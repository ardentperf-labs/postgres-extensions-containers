package main

import (
	"go.yaml.in/yaml/v3"
	"testing"
)

func TestRecipeDepths(t *testing.T) {
	for path, want := range map[string]string{
		"h3/metadata.hcl": "debian", "pgrx/example/metadata.hcl": "pgrx", "universe/example/metadata.hcl": "universe",
		"source-build/metadata.hcl": "", "source-build/pgrx/example/metadata.hcl": "", "pgrx/templates/fixtures/metadata.hcl": "", "test/fixtures/metadata.hcl": "",
	} {
		if got := recipeFamily(path); got != want {
			t.Errorf("%s: %s != %s", path, got, want)
		}
	}
}

func TestLocationFamiliesPreserveSourceVersions(t *testing.T) {
	for _, family := range []string{"pgrx", "universe"} {
		m := &extensionMetadata{BuildSystem: family, Versions: versionMap{"trixie": {"18": {Package: "v1.2.3-preview.4"}}}}
		got, err := extensionImageVersion(m, "trixie", 18)
		if err != nil {
			t.Fatal(err)
		}
		if family != "debian" && got != "1.2.3-preview.4" {
			t.Fatal(got)
		}
	}
}

func TestCandidateCatalogRuntimeAndAcceptedDependencies(t *testing.T) {
	m := &extensionMetadata{Name: "example", BuildSystem: "universe", ExtensionControlPath: []string{"/extension"}, Env: map[string]string{"FOO": "bar"}, Versions: versionMap{"trixie": {"17": {Package: "v1"}}}}
	c := &ImageCatalog{}
	// Use the real catalog YAML shape rather than a parallel test structure.
	if err := decodeCatalogFixture(c); err != nil {
		t.Fatal(err)
	}
	deps := []*testingExtensionInfo{{Configuration: &ExtensionConfiguration{Name: "accepted"}}}
	got, err := candidateCatalog(c, m, imageLocator{ExtensionImage: "registry/example@sha256:abc", Distribution: "trixie", PgMajor: 17}, deps)
	if err != nil {
		t.Fatal(err)
	}
	exts := got.Spec.Images[0].Extensions
	if got.Spec.Images[0].Major != 17 || len(exts) != 2 || exts[1].ExtensionControlPath[0] != "/extension" || exts[1].Env[0].Value != "bar" {
		t.Fatalf("%+v", got)
	}
	deps[0].Configuration.Name = "missing"
	if _, err := candidateCatalog(got, m, imageLocator{ExtensionImage: "registry/example@sha256:abc", Distribution: "trixie", PgMajor: 17}, deps); err == nil {
		t.Fatal("accepted missing dependency")
	}
}

func decodeCatalogFixture(c *ImageCatalog) error {
	return yaml.Unmarshal([]byte(`spec:
  images:
  - major: 17
    image: postgres:17
    extensions:
    - name: accepted
      image:
        reference: registry/accepted@sha256:abc
`), c)
}

func TestInventoryDuplicateBeforeSelectionAndLocationContext(t *testing.T) {
	paths := []string{"debian/metadata.hcl", "pgrx/source/metadata.hcl", "universe/other/metadata.hcl", "source-build/templates/metadata.hcl"}
	inventory, err := loadRecipeInventory(paths, func(p string) (*extensionMetadata, error) {
		name := "source"
		if p == paths[0] {
			name = "debian"
		}
		if p == paths[2] {
			name = "other"
		}
		return &extensionMetadata{Name: name, BuildSystem: "legacy-ignored"}, nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(inventory) != 3 || inventory["source"].RecipePath != "pgrx/source" || inventory["other"].BuildSystem != "universe" {
		t.Fatalf("%+v", inventory)
	}
	_, err = loadRecipeInventory(paths, func(string) (*extensionMetadata, error) { return &extensionMetadata{Name: "duplicate"}, nil })
	if err == nil {
		t.Fatal("accepted duplicate logical names")
	}
}

func TestSmokeRequestContainsOnlyCatalogName(t *testing.T) {
	data, err := yaml.Marshal(&ExtensionConfiguration{Name: "example"})
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != "name: example\n" {
		t.Fatalf("Cluster overrides catalog fields: %s", data)
	}
}
