package main

import (
	"fmt"
	"regexp"
	"slices"
	"strings"
)

func sourceCatalogKey(name, os string, major int) string {
	return fmt.Sprintf("%s/%s/%d", name, os, major)
}

func validateRegistryOwner(owner string) error {
	if !regexp.MustCompile(`^[a-z0-9](?:[a-z0-9-]{0,37}[a-z0-9])?$`).MatchString(owner) {
		return fmt.Errorf("invalid GHCR registry owner: %s", owner)
	}
	return nil
}

func validateProductionReference(ref, registryOwner string) error {
	if err := validateRegistryOwner(registryOwner); err != nil {
		return err
	}
	if !regexp.MustCompile(`^ghcr\.io/`+regexp.QuoteMeta(registryOwner)+`/[a-z0-9-]+(?::[A-Za-z0-9_][A-Za-z0-9_.-]*)?@sha256:[a-f0-9]{64}$`).MatchString(ref) || strings.Contains(strings.Split(ref, "@")[0], "-testing") {
		return fmt.Errorf("expected immutable production image reference: %s", ref)
	}
	return nil
}

// Identify the target using the actual index annotations, never artifact names.
func acceptedSourceKey(ref string, a map[string]string, sha string, recipes map[string]*extensionMetadata, registryOwner string) (string, error) {
	if err := validateProductionReference(ref, registryOwner); err != nil {
		return "", err
	}
	if !regexp.MustCompile(`^[a-f0-9]{40}$`).MatchString(sha) || a["org.opencontainers.image.revision"] != sha {
		return "", fmt.Errorf("accepted image has stale or missing source SHA")
	}
	os, major, err := parseImageCoordinates(a)
	if err != nil {
		return "", err
	}
	if !slices.Contains(SupportedDistributions, os) {
		return "", fmt.Errorf("unsupported accepted distribution")
	}
	for _, m := range recipes {
		repo := strings.Split(strings.Split(ref, "@")[0], ":")[0]
		if repo != "ghcr.io/"+registryOwner+"/"+m.ImageName {
			continue
		}
		if m.BuildSystem != pgrxBuildSystem && m.BuildSystem != universeBuildSystem {
			continue
		}
		if !buildMatrixFromMetadata(m).contains(os, fmt.Sprint(major)) {
			return "", fmt.Errorf("unsupported accepted target")
		}
		version, err := extensionImageVersion(m, os, major)
		if err != nil {
			return "", err
		}
		if a["org.opencontainers.image.version"] != version {
			return "", fmt.Errorf("accepted image version differs from recipe")
		}
		if a["org.opencontainers.image.title"] != fmt.Sprintf("%s %s %d %s", m.Name, version, major, os) {
			return "", fmt.Errorf("accepted image identity differs from recipe")
		}
		return sourceCatalogKey(m.Name, os, major), nil
	}
	return "", fmt.Errorf("accepted image does not identify a source recipe: %s", ref)
}

func sourceCatalogConfiguration(m *extensionMetadata, os string, major int, accepted map[string]string, previous []*ImageCatalog, registryOwner string) (*ExtensionConfiguration, error) {
	if ref := accepted[sourceCatalogKey(m.Name, os, major)]; ref != "" {
		return generateExtensionConfiguration(m, ref)
	}
	for _, c := range previous {
		if c.Metadata.Labels[LabelImageOS] != os {
			continue
		}
		for _, image := range c.Spec.Images {
			if image.Major != major {
				continue
			}
			for _, ext := range image.Extensions {
				if ext.Name == m.Name {
					if err := validateProductionReference(ext.ImageVolumeSource.Reference, registryOwner); err != nil {
						return nil, err
					}
					return &ext, nil
				}
			}
		}
	}
	return nil, fmt.Errorf("no accepted source release for %s/%s/%d", m.Name, os, major)
}
