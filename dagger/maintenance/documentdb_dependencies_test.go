package main

import (
	"context"
	"os"
	"testing"
)

func TestDocumentDBTestingValuesDependencies(t *testing.T) {
	contents, err := os.ReadFile("../../documentdb/metadata.hcl")
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	source := dag.Directory().WithNewFile("documentdb/metadata.hcl", string(contents))
	metadata, err := parseExtensionMetadata(ctx, source.Directory("documentdb"))
	if err != nil {
		t.Fatal(err)
	}
	configs, err := generateTestingValuesExtensions(ctx, source, metadata,
		imageLocator{ExtensionImage: "registry.example/documentdb-testing:1", PgMajor: 18, Distribution: "trixie"}, nil)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"documentdb", "pg-cron", "pgvector", "postgis", "rum"}
	if len(configs) != len(want) {
		t.Fatalf("got %d mounted extensions, want %v", len(configs), want)
	}
	for i, name := range want {
		if configs[i].Name != name {
			t.Errorf("extension %d: got %q, want %q", i, configs[i].Name, name)
		}
		if i > 0 && configs[i].ImageVolumeSource.Reference != "" {
			t.Errorf("dependency %q overrides catalog image", name)
		}
	}
}
