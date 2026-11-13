package main

import (
	"fmt"
	"strings"
)

// candidateCatalog uses accepted catalog entries for dependencies and replaces
// only the tested extension, preserving the selected base image and runtime fields.
func candidateCatalog(catalog *ImageCatalog, metadata *extensionMetadata, locator imageLocator, dependencies []*testingExtensionInfo) (*ImageCatalog, error) {
	if !strings.Contains(locator.ExtensionImage, "@sha256:") {
		return nil, fmt.Errorf("candidate image must use a digest")
	}
	if !buildMatrixFromMetadata(metadata).contains(locator.Distribution, fmt.Sprint(locator.PgMajor)) {
		return nil, fmt.Errorf("unsupported candidate target")
	}
	for i := range catalog.Spec.Images {
		img := &catalog.Spec.Images[i]
		if img.Major != locator.PgMajor {
			continue
		}
		for _, dep := range dependencies {
			if dep.Configuration == nil {
				continue
			}
			found := false
			for _, ext := range img.Extensions {
				if ext.Name == dep.Configuration.Name {
					found = true
				}
			}
			if !found {
				return nil, fmt.Errorf("dependency %q missing from accepted catalog", dep.Configuration.Name)
			}
		}
		config, err := generateExtensionConfiguration(metadata, locator.ExtensionImage)
		if err != nil {
			return nil, err
		}
		var extensions []ExtensionConfiguration
		for _, ext := range img.Extensions {
			if ext.Name != metadata.Name {
				extensions = append(extensions, ext)
			}
		}
		img.Extensions = append(extensions, *config)
		catalog.Spec.Images = catalog.Spec.Images[i : i+1]
		catalog.Metadata.Name = "candidate-" + metadata.Name
		return catalog, nil
	}
	return nil, fmt.Errorf("PostgreSQL major %d missing from accepted catalog", locator.PgMajor)
}
