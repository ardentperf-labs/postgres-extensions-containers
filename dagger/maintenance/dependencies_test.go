// SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"slices"
	"strings"
	"testing"
)

func TestDependencyOrder(t *testing.T) {
	graph := map[string]*extensionMetadata{
		"app":    {RequiredExtensions: []string{"left", "right", "base-image:plpgsql", "postgis"}},
		"left":   {RequiredExtensions: []string{"shared"}},
		"right":  {RequiredExtensions: []string{"shared", "base-image:plpgsql"}},
		"shared": {},
	}
	lookup := func(name string) (*extensionMetadata, error) { return graph[name], nil }
	got, err := dependencyOrder("app", lookup)
	want := []string{"shared", "left", "base-image:plpgsql", "right", "postgis", "app"}
	if err != nil || !slices.Equal(got, want) {
		t.Fatalf("order=%v err=%v; want %v", got, err, want)
	}
	graph["shared"].RequiredExtensions = []string{"app"}
	if _, err := dependencyOrder("app", lookup); err == nil || !strings.Contains(err.Error(), "cycle") {
		t.Fatalf("expected cycle error; got %v", err)
	}
	graph["shared"].RequiredExtensions = []string{"../outside"}
	if _, err := dependencyOrder("app", lookup); err == nil {
		t.Fatal("accepted dependency path outside repository")
	}
	graph["shared"].RequiredExtensions = []string{"base-image:"}
	if _, err := dependencyOrder("app", lookup); err == nil {
		t.Fatal("accepted empty base-image dependency")
	}
}

func TestDependencyImageReference(t *testing.T) {
	dep := "ghcr.io/cnpg-extensions/roaringbitmap:1.2.0-18-trixie"
	cases := []struct{ parent, want string }{
		{"registry.pg-extensions:5000/pgfaceting-testing:0.2.0-18-trixie", "registry.pg-extensions:5000/roaringbitmap-testing:1.2.0-18-trixie"},
		{"ghcr.io/cnpg-extensions/pgfaceting-testing:0.2.0-20260929-18-trixie", "ghcr.io/cnpg-extensions/roaringbitmap-testing:1.2.0-18-trixie"},
		{"localhost:5000/nested/parent-testing@sha256:abcd", "localhost:5000/nested/roaringbitmap-testing:1.2.0-18-trixie"},
		{"ghcr.io/cnpg-extensions/pgfaceting:0.2.0-18-trixie", dep},
	}
	for _, c := range cases {
		if got := dependencyImageReference(c.parent, dep); got != c.want {
			t.Errorf("%s: got %s; want %s", c.parent, got, c.want)
		}
	}
}

func TestMergeTestingSettings(t *testing.T) {
	infos := []*testingExtensionInfo{
		{SharedPreloadLibraries: []string{"dependency"}, PostgreSQLParameters: map[string]string{"wal_level": "logical"}},
		{SharedPreloadLibraries: []string{"dependency", "parent"}, PostgreSQLParameters: map[string]string{"wal_level": "logical"}},
	}
	libs, params, err := mergeTestingSettings(infos)
	if err != nil || !slices.Equal(libs, []string{"dependency", "parent"}) || params["wal_level"] != "logical" {
		t.Fatalf("libs=%v params=%v err=%v", libs, params, err)
	}
	infos[1].PostgreSQLParameters["wal_level"] = "replica"
	if _, _, err := mergeTestingSettings(infos); err == nil {
		t.Fatal("accepted conflicting dependency settings")
	}
}

func TestLocalImageRegistry(t *testing.T) {
	m := &extensionMetadata{Name: "pgfaceting", ImageName: "pgfaceting", Versions: versionMap{"trixie": {"18": {Package: "0.2.0-6.pgdg13+1"}}}}
	got, err := getExtensionImage(m, "trixie", 18)
	if err != nil || got != "ghcr.io/cnpg-extensions/pgfaceting:0.2.0-18-trixie" {
		t.Fatalf("got=%s err=%v", got, err)
	}
}

func TestCatalogAndBundledSQLDependencies(t *testing.T) {
	image, sql, found, err := parseCatalogDependency("catalog:pgvector:vector")
	if err != nil || !found || image != "pgvector" || sql != "vector" {
		t.Fatalf("catalog alias: %s %s %v %v", image, sql, found, err)
	}
	for _, invalid := range []string{"catalog:pgvector", "catalog:pgvector:", "catalog:../escape:vector", "catalog:pgvector:vector:extra"} {
		if _, _, _, err := parseCatalogDependency(invalid); err == nil {
			t.Fatalf("accepted %q", invalid)
		}
	}
	lookup := func(name string) (*extensionMetadata, error) {
		if name != "documentdb" {
			t.Fatalf("attempted image lookup for SQL/catalog prerequisite %q", name)
		}
		return &extensionMetadata{RequiredExtensions: []string{"catalog:pgvector:vector", "image-sql:documentdb_core", "base-image:tsm_system_rows"}}, nil
	}
	got, err := dependencyOrder("documentdb", lookup)
	want := []string{"catalog:pgvector:vector", "image-sql:documentdb_core", "base-image:tsm_system_rows", "documentdb"}
	if err != nil || !slices.Equal(got, want) {
		t.Fatalf("order=%v err=%v", got, err)
	}
	name, noImage, err := parseRequiredDependency("image-sql:documentdb_core")
	if err != nil || !noImage || name != "documentdb_core" {
		t.Fatalf("bundled SQL: %s %v %v", name, noImage, err)
	}
	if _, _, err := parseRequiredDependency("image-sql:"); err == nil {
		t.Fatal("accepted empty bundled SQL name")
	}
}
