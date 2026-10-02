package main

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"dagger/maintenance/internal/dagger"
	"github.com/google/go-containerregistry/pkg/name"
)

type TestingValues struct {
	Name                   string                    `yaml:"name"`
	SharedPreloadLibraries []string                  `yaml:"shared_preload_libraries"`
	PostgresqlParameters   map[string]string         `yaml:"postgresql_parameters"`
	PgImage                string                    `yaml:"pg_image"`
	PgMajor                int                       `yaml:"pg_major"`
	Distribution           string                    `yaml:"distribution"`
	Extensions             []*ExtensionConfiguration `yaml:"extensions"`
}

const baseImageDependencyPrefix = "base-image:"

type imageLocator struct {
	ExtensionImage string
	PgMajor        int
	Distribution   string
}

type testDependency struct {
	Name     string
	ImageRef string
}

func generateTestingValuesExtensions(
	ctx context.Context,
	source *dagger.Directory,
	metadata *extensionMetadata,
	locator imageLocator,
	testDependencies []testDependency,
) ([]*ExtensionConfiguration, error) {
	var out []*ExtensionConfiguration
	configuration, err := generateExtensionConfiguration(metadata, locator.ExtensionImage)
	if err != nil {
		return nil, err
	}
	out = append(out, configuration)

	seen := map[string]struct{}{metadata.Name: {}}
	type dependency struct {
		name     string
		testOnly bool
	}
	requiredExtensions := make([]dependency, 0, len(metadata.RequiredExtensions)+len(testDependencies))
	for _, testDependency := range testDependencies {
		// Explicit references are useful for one-level external test fixtures
		// (for example, an upstream PostGIS image). Target names are resolved
		// only from repository metadata below.
		if testDependency.ImageRef != "" {
			if _, ok := seen[testDependency.Name]; ok {
				continue
			}
			out = append(out, &ExtensionConfiguration{
				Name: testDependency.Name,
				ImageVolumeSource: ImageVolumeSource{
					Reference: testDependency.ImageRef,
				},
			})
			seen[testDependency.Name] = struct{}{}
			continue
		}
		requiredExtensions = append(requiredExtensions, dependency{name: testDependency.Name, testOnly: true})
	}
	for _, name := range metadata.RequiredExtensions {
		requiredExtensions = append(requiredExtensions, dependency{name: name})
	}
	for _, requiredDependency := range requiredExtensions {
		dep, isBaseImageDependency, err := parseRequiredDependency(requiredDependency.name)
		if err != nil {
			return nil, err
		}
		if isBaseImageDependency {
			continue
		}
		if _, ok := seen[dep]; ok {
			continue
		}
		seen[dep] = struct{}{}

		depExists, err := source.Exists(ctx, dep)
		if err != nil {
			return nil, err
		}
		if !depExists {
			if requiredDependency.testOnly {
				return nil, fmt.Errorf("required test extension %q has no target directory or metadata.hcl", dep)
			}
			out = append(out, &ExtensionConfiguration{Name: dep})
			continue
		}

		depMetadata, err := parseExtensionMetadata(ctx, source.Directory(dep))
		if err != nil {
			return nil, fmt.Errorf("failed to parse dependency metadata %q: %w", dep, err)
		}
		requiredExtensionImage, err := getExtensionImage(depMetadata, locator.Distribution, locator.PgMajor)
		if err != nil {
			return nil, err
		}
		if requiredDependency.testOnly {
			requiredExtensionImage, err = localTestDependencyImage(
				locator.ExtensionImage,
				depMetadata,
				locator.Distribution,
				locator.PgMajor,
				requiredExtensionImage,
			)
			if err != nil {
				return nil, err
			}
		}
		depConfiguration, err := generateExtensionConfiguration(depMetadata, requiredExtensionImage)
		if err != nil {
			return nil, err
		}

		out = append(out, depConfiguration)
	}

	return out, nil
}

func readTestDependencies(ctx context.Context, extensionDirectory *dagger.Directory, distribution string) ([]testDependency, error) {
	dependenciesPath := "test/dependencies." + distribution
	exists, err := extensionDirectory.Exists(ctx, dependenciesPath)
	if err != nil {
		return nil, err
	}
	if !exists {
		dependenciesPath = "test/dependencies"
		exists, err = extensionDirectory.Exists(ctx, dependenciesPath)
		if err != nil {
			return nil, err
		}
		if !exists {
			return nil, nil
		}
	}

	contents, err := extensionDirectory.File(dependenciesPath).Contents(ctx)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", dependenciesPath, err)
	}
	return parseTestDependencies(contents)
}

func parseTestDependencies(contents string) ([]testDependency, error) {
	var dependencies []testDependency
	seen := make(map[string]struct{})
	for lineNumber, line := range strings.Split(contents, "\n") {
		line = strings.TrimSpace(strings.SplitN(line, "#", 2)[0])
		if line == "" {
			continue
		}
		nameAndImage := strings.SplitN(line, "=", 2)
		dependency := testDependency{Name: strings.TrimSpace(nameAndImage[0])}
		if !testDependencyName.MatchString(dependency.Name) {
			return nil, fmt.Errorf("invalid test dependency %q on line %d", line, lineNumber+1)
		}
		if len(nameAndImage) == 2 {
			dependency.ImageRef = strings.TrimSpace(nameAndImage[1])
			if dependency.ImageRef == "" {
				return nil, fmt.Errorf("test dependency %q has an empty image reference on line %d", dependency.Name, lineNumber+1)
			}
			if _, err := name.ParseReference(dependency.ImageRef, name.Insecure); err != nil {
				return nil, fmt.Errorf("invalid image reference for test dependency %q on line %d: %w", dependency.Name, lineNumber+1, err)
			}
		}
		if _, ok := seen[dependency.Name]; ok {
			continue
		}
		seen[dependency.Name] = struct{}{}
		dependencies = append(dependencies, dependency)
	}
	return dependencies, nil
}

var testDependencyName = regexp.MustCompile(`^[a-z0-9][a-z0-9_-]*$`)

func localTestDependencyImage(targetImage string, dependency *extensionMetadata, distribution string, pgMajor int, publishedImage string) (string, error) {
	targetReference, err := name.ParseReference(targetImage, name.Insecure)
	if err != nil {
		return "", fmt.Errorf("parse target test image reference: %w", err)
	}
	targetRepository := targetReference.Context().Name()
	separator := strings.LastIndex(targetRepository, "/")
	if separator < 0 || !strings.HasSuffix(targetRepository[separator+1:], "-testing") {
		return publishedImage, nil
	}

	publishedReference, err := name.ParseReference(publishedImage, name.Insecure)
	if err != nil {
		return "", fmt.Errorf("parse published dependency image reference: %w", err)
	}
	dependencyRepository := targetRepository[:separator+1] + dependency.ImageName + "-testing"
	localReference := dependencyRepository + ":" + publishedReference.Identifier()
	if _, err := name.ParseReference(localReference, name.Insecure); err != nil {
		return "", fmt.Errorf("build local test dependency image reference %q: %w", localReference, err)
	}
	return localReference, nil
}

func parseRequiredDependency(dependency string) (string, bool, error) {
	if !strings.HasPrefix(dependency, baseImageDependencyPrefix) {
		return dependency, false, nil
	}

	name := strings.TrimPrefix(dependency, baseImageDependencyPrefix)
	if name == "" {
		return "", false, fmt.Errorf("base-image dependency %q has no extension name", dependency)
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
