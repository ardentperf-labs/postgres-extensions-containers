package main

import (
	"reflect"
	"strings"
	"testing"
)

func TestSourceCatalogRetainsUnpublishedVersion(t *testing.T) {
	m := &extensionMetadata{Name: "sample", BuildSystem: universeBuildSystem}
	c := &ImageCatalog{}
	c.Metadata.Labels = map[string]string{LabelImageOS: "trixie"}
	// Use the actual catalog decoder to represent a prior accepted release.
	ref := "ghcr.io/cnpg-extensions/sample@sha256:" + strings.Repeat("a", 64)
	prior := ExtensionConfiguration{Name: "sample", ImageVolumeSource: ImageVolumeSource{Reference: ref}}
	prior.BinPath = []string{"/accepted/bin"}
	prior.DynamicLibraryPath = []string{"/accepted/lib"}
	m.BinPath = []string{"/unaccepted/bin"}
	m.DynamicLibraryPath = []string{"/unaccepted/lib"}
	// The current recipe's version and runtime settings must not leak into retention.
	c.Spec.Images = append(c.Spec.Images, struct {
		Major      int                      `yaml:"major"`
		Image      string                   `yaml:"image"`
		Extensions []ExtensionConfiguration `yaml:"extensions,omitempty"`
	}{Major: 18, Extensions: []ExtensionConfiguration{prior}})
	got, err := sourceCatalogConfiguration(m, "trixie", 18, nil, []*ImageCatalog{c}, "cnpg-extensions")
	if err != nil || got.ImageVolumeSource.Reference != ref {
		t.Fatalf("retention: %v %v", got, err)
	}
	if !reflect.DeepEqual(*got, prior) {
		t.Fatalf("retained runtime settings changed: %#v", got)
	}
	replacement, err := sourceCatalogConfiguration(m, "trixie", 18, map[string]string{sourceCatalogKey("sample", "trixie", 18): ref}, []*ImageCatalog{c}, "cnpg-extensions")
	if err != nil || !reflect.DeepEqual(replacement.BinPath, m.BinPath) {
		t.Fatalf("accepted replacement settings: %#v %v", replacement, err)
	}
	if _, err := sourceCatalogConfiguration(m, "trixie", 18, nil, nil, "cnpg-extensions"); err == nil {
		t.Fatal("initial unpublished release must fail")
	}
	forkRef := strings.Replace(ref, "cnpg-extensions", "ardentperf-labs", 1)
	c.Spec.Images[0].Extensions[0].ImageVolumeSource.Reference = forkRef
	if got, err := sourceCatalogConfiguration(m, "trixie", 18, nil, []*ImageCatalog{c}, "ardentperf-labs"); err != nil || got.ImageVolumeSource.Reference != forkRef {
		t.Fatalf("fork retention: %v %v", got, err)
	}
	if _, err := sourceCatalogConfiguration(m, "trixie", 18, nil, []*ImageCatalog{c}, "cnpg-extensions"); err == nil {
		t.Fatal("fork previous reference accepted for upstream owner")
	}
	c.Spec.Images[0].Extensions[0].ImageVolumeSource.Reference = "ghcr.io/cnpg-extensions/sample-testing@sha256:" + strings.Repeat("a", 64)
	if _, err := sourceCatalogConfiguration(m, "trixie", 18, nil, []*ImageCatalog{c}, "cnpg-extensions"); err == nil {
		t.Fatal("testing image accepted")
	}
}

func TestAcceptedSourceIdentity(t *testing.T) {
	sha := strings.Repeat("b", 40)
	ref := "ghcr.io/cnpg-extensions/sample@sha256:" + strings.Repeat("a", 64)
	m := &extensionMetadata{Name: "sample", ImageName: "sample", BuildSystem: universeBuildSystem, Versions: versionMap{"trixie": {"18": {Package: "v1.2-rc.3"}}}}
	annotations := map[string]string{AnnotationImageBaseOS: "trixie", AnnotationImageBasePgMajor: "18", "org.opencontainers.image.revision": sha, "org.opencontainers.image.version": "1.2-rc.3", "org.opencontainers.image.title": "sample 1.2-rc.3 18 trixie"}
	recipes := map[string]*extensionMetadata{"universe/sample": m}
	if _, err := acceptedSourceKey(ref, annotations, sha, recipes, "cnpg-extensions"); err != nil {
		t.Fatal(err)
	}
	if _, err := acceptedSourceKey(ref, annotations, strings.Repeat("c", 40), recipes, "cnpg-extensions"); err == nil {
		t.Fatal("stale SHA accepted")
	}
	annotations[AnnotationImageBasePgMajor] = "17"
	if _, err := acceptedSourceKey(ref, annotations, sha, recipes, "cnpg-extensions"); err == nil {
		t.Fatal("unsupported combination accepted")
	}
}

func TestForkSourceCatalogOwner(t *testing.T) {
	sha := strings.Repeat("b", 40)
	ref := "ghcr.io/ardentperf-labs/sample@sha256:" + strings.Repeat("a", 64)
	m := &extensionMetadata{Name: "sample", ImageName: "sample", BuildSystem: universeBuildSystem, Versions: versionMap{"trixie": {"18": {Package: "v1.2"}}}}
	annotations := map[string]string{AnnotationImageBaseOS: "trixie", AnnotationImageBasePgMajor: "18", "org.opencontainers.image.revision": sha, "org.opencontainers.image.version": "1.2", "org.opencontainers.image.title": "sample 1.2 18 trixie"}
	recipes := map[string]*extensionMetadata{"universe/sample": m}
	for _, owner := range []string{"cnpg-extensions", "another-owner", "ardentperf-labs/other", "example.com"} {
		if _, err := acceptedSourceKey(ref, annotations, sha, recipes, owner); err == nil {
			t.Fatalf("fork reference accepted for owner %q", owner)
		}
	}
	if key, err := acceptedSourceKey(ref, annotations, sha, recipes, "ardentperf-labs"); err != nil || key != "sample/trixie/18" {
		t.Fatalf("fork acceptance: %q %v", key, err)
	}
	for _, badRef := range []string{
		strings.Replace(ref, "ghcr.io", "example.com", 1),
		strings.Replace(ref, "sample@", "sample-testing@", 1),
		strings.Split(ref, "@")[0] + ":latest",
		strings.Replace(ref, "/sample@", "/other@", 1),
	} {
		if _, err := acceptedSourceKey(badRef, annotations, sha, recipes, "ardentperf-labs"); err == nil {
			t.Fatalf("invalid fork reference accepted: %s", badRef)
		}
	}
	for _, field := range []string{"org.opencontainers.image.revision", "org.opencontainers.image.version", "org.opencontainers.image.title", AnnotationImageBasePgMajor} {
		original := annotations[field]
		annotations[field] = "invalid"
		if _, err := acceptedSourceKey(ref, annotations, sha, recipes, "ardentperf-labs"); err == nil {
			t.Fatalf("invalid fork annotation accepted: %s", field)
		}
		annotations[field] = original
	}
}
