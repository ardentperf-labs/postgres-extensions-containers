package main

import (
	"encoding/base64"
	"strings"
	"testing"
)

func TestParseRunnerPackages(t *testing.T) {
	packages, err := parseRunnerPackages("# test-only tooling\npython3\nlibpq-dev # comment\npython3\n")
	if err != nil {
		t.Fatal(err)
	}
	if got, want := strings.Join(packages, ","), "python3,libpq-dev"; got != want {
		t.Fatalf("packages = %q, want %q", got, want)
	}

	if _, err := parseRunnerPackages("postgresql-18-credcheck; touch /tmp/pwned"); err == nil {
		t.Fatal("expected invalid package name to be rejected")
	}
}

func TestValidateRunnerPackagesRejectsExtensionUnderTest(t *testing.T) {
	if err := validateRunnerPackages([]string{"postgresql-18-pg-qualstats"}, "pg-qualstats", 18); err == nil {
		t.Fatal("expected extension package to be rejected")
	}
	if err := validateRunnerPackages([]string{"python3"}, "pg-qualstats", 18); err != nil {
		t.Fatalf("valid test-only package was rejected: %v", err)
	}
}

func TestParseTestDependencies(t *testing.T) {
	dependencies, err := parseTestDependencies("# one-level image targets\npgtap\npostgis # provided by CNPG\npgtap\n")
	if err != nil {
		t.Fatal(err)
	}
	var names []string
	for _, dependency := range dependencies {
		names = append(names, dependency.Name)
	}
	if got, want := strings.Join(names, ","), "pgtap,postgis"; got != want {
		t.Fatalf("dependencies = %q, want %q", got, want)
	}
	if _, err := parseTestDependencies("../pgtap"); err == nil {
		t.Fatal("expected unsafe dependency target to be rejected")
	}
	if got, err := parseTestDependencies("postgis=ghcr.io/example/postgis:1.2@sha256:" + strings.Repeat("a", 64)); err != nil {
		t.Fatal(err)
	} else if len(got) != 1 || got[0].Name != "postgis" || got[0].ImageRef == "" {
		t.Fatalf("explicit image dependency = %#v, want one named, pinned dependency", got)
	}
}

func TestLocalTestDependencyImage(t *testing.T) {
	dependency := &extensionMetadata{
		Name:      "pgtap",
		ImageName: "pgtap",
		Versions: versionMap{
			"trixie": {"18": {Package: "1.5.2-1.pgdg13+1"}},
		},
	}
	image, err := localTestDependencyImage(
		"registry.pg-extensions:5000/asn1oid-testing:0.1.0-18-trixie",
		dependency,
		"trixie",
		18,
		"ghcr.io/cloudnative-pg/pgtap:1.5.2-18-trixie",
	)
	if err != nil {
		t.Fatal(err)
	}
	if want := "registry.pg-extensions:5000/pgtap-testing:1.5.2-18-trixie"; image != want {
		t.Fatalf("local dependency image = %q, want %q", image, want)
	}
	namespaced, err := localTestDependencyImage(
		"registry.example:5000/team/asn1oid-testing:0.1.0-18-trixie",
		dependency,
		"trixie",
		18,
		"ghcr.io/cloudnative-pg/pgtap:1.5.2-18-trixie",
	)
	if err != nil {
		t.Fatal(err)
	}
	if want := "registry.example:5000/team/pgtap-testing:1.5.2-18-trixie"; namespaced != want {
		t.Fatalf("namespaced local dependency image = %q, want %q", namespaced, want)
	}

	remote, err := localTestDependencyImage(
		"ghcr.io/cloudnative-pg/asn1oid:0.1.0-18-trixie",
		dependency,
		"trixie",
		18,
		"ghcr.io/cloudnative-pg/pgtap:1.5.2-18-trixie",
	)
	if err != nil {
		t.Fatal(err)
	}
	if want := "ghcr.io/cloudnative-pg/pgtap:1.5.2-18-trixie"; remote != want {
		t.Fatalf("published dependency image = %q, want %q", remote, want)
	}
}

func TestNativeTestCommandUsesCNPGSocketAndRegressionTools(t *testing.T) {
	args := strings.Join(nativeTestCommandArgs("postgres-1", "/var/lib/postgresql/data/upstream-tests/pg-repack/test", 18), " ")
	for _, want := range []string{
		"PGHOST=/controller/run",
		"PGUSER=postgres",
		"PG_REGRESS=/var/lib/postgresql/data/upstream-tests/pg-repack/test/.harness/bin/pg_regress",
		"PG_ISOLATION_REGRESS=/var/lib/postgresql/data/upstream-tests/pg-repack/test/.harness/bin/pg_isolation_regress",
		"dropdb --if-exists --maintenance-db=postgres contrib_regression",
		"export PGDATABASE=contrib_regression",
	} {
		if !strings.Contains(args, want) {
			t.Fatalf("native command args do not contain %q:\n%s", want, args)
		}
	}
}

func TestMergeClusterSettingsPreservesMetadataParameters(t *testing.T) {
	base := `apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ($values.name)
spec:
  postgresql:
    parameters: ($values.postgresql_parameters)
    shared_preload_libraries: ($values.shared_preload_libraries)
`
	overlay := `apiVersion: postgresql.cnpg.io/v1
kind: Cluster
spec:
  postgresql:
    parameters:
      cron.database_name: contrib_regression
`
	values := TestingValues{
		PostgresqlParameters:   map[string]string{"credcheck.password_min_length": "12"},
		SharedPreloadLibraries: []string{"credcheck"},
	}
	merged, values, err := mergeClusterSettings(base, overlay, values)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(merged, "cron.database_name") {
		t.Fatalf("test parameter should use merged values, not replace the values expression:\n%s", merged)
	}
	if got, want := values.PostgresqlParameters["credcheck.password_min_length"], "12"; got != want {
		t.Fatalf("metadata parameter = %q, want %q", got, want)
	}
	if got, want := values.PostgresqlParameters["cron.database_name"], "contrib_regression"; got != want {
		t.Fatalf("test parameter = %q, want %q", got, want)
	}
}

func TestMergeClusterSettingsAddsTestOnlyExtensionPaths(t *testing.T) {
	base := `apiVersion: postgresql.cnpg.io/v1
kind: Cluster
spec:
  postgresql:
    extensions: ($values.extensions)
`
	overlay := `apiVersion: postgresql.cnpg.io/v1
kind: Cluster
spec:
  postgresql:
    extensions:
      - name: postgis
        ld_library_path:
          - system
`
	values := TestingValues{Extensions: []*ExtensionConfiguration{
		{Name: "h3", ImageVolumeSource: ImageVolumeSource{Reference: "registry.example/h3:1"}},
		{Name: "postgis", ImageVolumeSource: ImageVolumeSource{Reference: "ghcr.io/example/postgis:1"}},
	}}
	merged, values, err := mergeClusterSettings(base, overlay, values)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(merged, "ld_library_path") {
		t.Fatalf("test extension path should use merged values, not replace the values expression:\n%s", merged)
	}
	if got, want := values.Extensions[0].ImageVolumeSource.Reference, "registry.example/h3:1"; got != want {
		t.Fatalf("target extension image = %q, want %q", got, want)
	}
	if got, want := values.Extensions[1].ImageVolumeSource.Reference, "ghcr.io/example/postgis:1"; got != want {
		t.Fatalf("test dependency image = %q, want %q", got, want)
	}
	if got, want := strings.Join(values.Extensions[1].LdLibraryPath, ","), "system"; got != want {
		t.Fatalf("test dependency library path = %q, want %q", got, want)
	}
}

func TestDecodeKubernetesSecret(t *testing.T) {
	want := "temporary-password"
	got, err := decodeKubernetesSecret(base64.StdEncoding.EncodeToString([]byte(want)) + "\n")
	if err != nil {
		t.Fatal(err)
	}
	if got != want {
		t.Fatalf("password = %q, want %q", got, want)
	}
	if _, err := decodeKubernetesSecret("not-base64!"); err == nil {
		t.Fatal("expected invalid secret encoding to be rejected")
	}
}
