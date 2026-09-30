package main

import (
	"context"
	"fmt"
	"strings"

	"dagger/maintenance/internal/dagger"
)

type ExtensionSpec struct {
	Ensure  string `yaml:"ensure"`
	Name    string `yaml:"name"`
	Version string `yaml:"version"`
}

type DatabaseConfig struct {
	ExtensionsSpec []ExtensionSpec `yaml:"extensions_spec,omitempty"`
}

type TestingValues struct {
	Name                   string                    `yaml:"name"`
	SQLName                string                    `yaml:"sql_name"`
	SharedPreloadLibraries []string                  `yaml:"shared_preload_libraries"`
	PostgresqlParameters   map[string]string         `yaml:"postgresql_parameters"`
	PgImage                string                    `yaml:"pg_image"`
	Version                string                    `yaml:"version"`
	CreateExtension        bool                      `yaml:"create_extension"`
	Extensions             []*ExtensionConfiguration `yaml:"extensions"`
	DatabaseConfig         *DatabaseConfig           `yaml:"database_config"`
	DatabaseAssertStatus   map[string]any            `yaml:"database_assert_status"`
}

type testingExtensionInfo struct {
	SharedPreloadLibraries []string
	PostgreSQLParameters   map[string]string
	Configuration          *ExtensionConfiguration
	SQLName                string
	Version                string
	CreateExtension        bool
}

const baseImageDependencyPrefix = "base-image:"

type imageLocator struct {
	ExtensionImage string
	PgMajor        int
	SQLVersion     string
	Distribution   string
}

func generateTestingValuesExtensions(
	ctx context.Context,
	source *dagger.Directory,
	metadata *extensionMetadata,
	locator imageLocator,
	registryUsername string,
	registryPassword *dagger.Secret,
) ([]*testingExtensionInfo, error) {
	lookup := dependencyLookup(ctx, source)
	ordered, err := dependencyOrder(metadata.Name, lookup)
	if err != nil {
		return nil, err
	}
	var out []*testingExtensionInfo
	for _, name := range ordered {
		image, sql, catalog, err := parseCatalogDependency(name)
		if err != nil {
			return nil, err
		}
		if catalog {
			out = append(out, &testingExtensionInfo{Configuration: &ExtensionConfiguration{Name: image}, SQLName: sql, CreateExtension: true})
			continue
		}
		dep, base, err := parseRequiredDependency(name)
		if err != nil {
			return nil, err
		}
		if base {
			out = append(out, &testingExtensionInfo{SQLName: dep, CreateExtension: true})
			continue
		}
		depMetadata, err := lookup(dep)
		if err != nil {
			return nil, err
		}
		if depMetadata == nil {
			out = append(out, &testingExtensionInfo{Configuration: &ExtensionConfiguration{Name: dep}, SQLName: dep, CreateExtension: true})
			continue
		}
		image, version := locator.ExtensionImage, locator.SQLVersion
		if dep != metadata.Name {
			image, err = getExtensionImage(depMetadata, locator.Distribution, locator.PgMajor)
			if err != nil {
				return nil, err
			}
			image = dependencyImageReference(locator.ExtensionImage, image)
			annotations, err := getImageAnnotations(ctx, image, registryUsername, registryPassword)
			if err != nil {
				return nil, err
			}
			version = annotations[AnnotationImageSQLVersion]
			if version == "" && depMetadata.CreateExtension {
				return nil, fmt.Errorf("extension image %s lacks SQL version annotation", image)
			}
		}
		configuration, err := generateExtensionConfiguration(depMetadata, image)
		if err != nil {
			return nil, err
		}
		// Local testing tags are reused after rebuilds. Resolve them on each pod
		// creation so an older cached image cannot make a changed build pass.
		configuration.ImageVolumeSource.PullPolicy = "Always"
		out = append(out, &testingExtensionInfo{Configuration: configuration,
			SQLName: depMetadata.SQLName, Version: version, CreateExtension: depMetadata.CreateExtension,
			SharedPreloadLibraries: depMetadata.SharedPreloadLibraries, PostgreSQLParameters: depMetadata.PostgresqlParameters})
	}

	return out, nil
}

func parseRequiredDependency(dependency string) (string, bool, error) {
	prefix := baseImageDependencyPrefix
	if strings.HasPrefix(dependency, "image-sql:") {
		prefix = "image-sql:"
	}
	if !strings.HasPrefix(dependency, prefix) {
		return dependency, false, nil
	}

	name := strings.TrimPrefix(dependency, prefix)
	if name == "" {
		return "", false, fmt.Errorf("SQL dependency %q has no extension name", dependency)
	}

	return name, true, nil
}

func generateExtensionConfiguration(metadata *extensionMetadata, extensionImage string) (*ExtensionConfiguration, error) {
	targetExtensionImage := extensionImage
	if targetExtensionImage == "" {
		var err error
		targetExtensionImage, err = getDefaultExtensionImage(metadata)
		if err != nil {
			return nil, err
		}
	}

	return &ExtensionConfiguration{
		Name: metadata.Name,
		ImageVolumeSource: ImageVolumeSource{
			Reference: targetExtensionImage,
		},
		ExtensionControlPath: metadata.ExtensionControlPath,
		DynamicLibraryPath:   metadata.DynamicLibraryPath,
		LdLibraryPath:        metadata.LdLibraryPath,
		BinPath:              metadata.BinPath,
		Env:                  envMapToSlice(metadata.Env),
	}, nil
}

func generateDatabaseConfig(extensionInfos []*testingExtensionInfo) *DatabaseConfig {
	var databaseConfig DatabaseConfig
	for _, info := range extensionInfos {
		if !info.CreateExtension {
			continue
		}

		databaseConfig.ExtensionsSpec = append(databaseConfig.ExtensionsSpec,
			ExtensionSpec{
				Ensure:  "present",
				Name:    info.SQLName,
				Version: info.Version,
			},
		)
	}

	return &databaseConfig
}

func generateDatabaseAssertStatus(extensionInfos []*testingExtensionInfo) map[string]any {
	// observedGeneration is intentionally omitted. CNPG reports the Database
	// metadata.generation it reconciled, and this fork's catalog-backed E2E
	// setup can legitimately produce a value other than 1. Upstream retains
	// the generation-1 assertion because its E2E setup uses imageName and
	// local dependency images. Keep this fork-local relaxation when syncing
	// changes from upstream; it is not an upstream CNPG behavior change.
	status := map[string]any{
		"applied": true,
	}

	var extensions []map[string]any
	for _, info := range extensionInfos {
		if !info.CreateExtension {
			continue
		}
		extensions = append(extensions, map[string]any{
			"applied": true,
			"name":    info.SQLName,
		})
	}
	if len(extensions) > 0 {
		status["extensions"] = extensions
	}

	return status
}

// Dependency settings must agree; silently replacing a preload requirement can
// make a healthy cluster hide a nonfunctional dependency.
func mergeTestingSettings(infos []*testingExtensionInfo) ([]string, map[string]string, error) {
	preloads := []string{}
	seen := map[string]bool{}
	parameters := map[string]string{}
	for _, info := range infos {
		for _, lib := range info.SharedPreloadLibraries {
			if !seen[lib] {
				preloads = append(preloads, lib)
				seen[lib] = true
			}
		}
		for key, value := range info.PostgreSQLParameters {
			if previous, found := parameters[key]; found && previous != value {
				return nil, nil, fmt.Errorf("conflicting dependency parameter %s: %q and %q", key, previous, value)
			}
			parameters[key] = value
		}
	}
	return preloads, parameters, nil
}
