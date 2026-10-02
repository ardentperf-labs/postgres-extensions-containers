package main

import (
	"context"
	"testing"
)

func TestTestingValuesPreserveCatalogDependenciesAndFixtureOverrides(t *testing.T) {
	// Local metadata must not turn a runtime dependency into a pinned image.
	// An empty version matrix makes accidental image selection fail, even
	// though catalog resolution can still supply the extension at runtime.
	source := dag.Directory().WithNewFile("runtime/metadata.hcl", `
metadata = {
    name = "runtime"
    sql_name = "runtime_sql"
    image_name = "must-not-be-selected"
    shared_preload_libraries = []
    postgresql_parameters = {}
    extension_control_path = []
    dynamic_library_path = []
    ld_library_path = []
    bin_path = []
    env = {}
    auto_update_os_libs = false
    required_extensions = []
    create_extension = true
    versions = {}
}
`)
	metadata := &extensionMetadata{
		Name: "target", RequiredExtensions: []string{"base-image:btree_gist", "runtime", "pgvector"},
	}
	const targetImage = "registry.example/target-testing:1"
	const fixtureImage = "registry.example/pgvector-testing:2"
	configs, err := generateTestingValuesExtensions(context.Background(), source, metadata,
		imageLocator{ExtensionImage: targetImage, PgMajor: 18, Distribution: "trixie"},
		[]testDependency{{Name: "pgvector", ImageRef: fixtureImage}})
	if err != nil {
		t.Fatal(err)
	}
	if len(configs) != 3 {
		t.Fatalf("got %d mounted extensions, want target, fixture and runtime dependency", len(configs))
	}
	if configs[0].ImageVolumeSource.Reference != targetImage || configs[1].Name != "pgvector" || configs[1].ImageVolumeSource.Reference != fixtureImage {
		t.Fatalf("target or fixture image override lost: %+v, %+v", configs[0], configs[1])
	}
	if configs[2].Name != "runtime" || configs[2].ImageVolumeSource.Reference != "" {
		t.Fatalf("runtime dependency no longer uses the catalog: %+v", configs[2])
	}
}
