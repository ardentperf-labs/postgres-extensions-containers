// SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"path"
	"regexp"
	"strings"

	"dagger/maintenance/internal/dagger"
)

var dependencyNamePattern = regexp.MustCompile(`^[a-z0-9_-]+$`)

// Catalog dependencies may have different image and SQL extension names.
func parseCatalogDependency(value string) (image, sql string, found bool, err error) {
	if !strings.HasPrefix(value, "catalog:") {
		return "", "", false, nil
	}
	parts := strings.Split(value, ":")
	if len(parts) != 3 || !dependencyNamePattern.MatchString(parts[1]) || !dependencyNamePattern.MatchString(parts[2]) {
		return "", "", true, fmt.Errorf("invalid catalog dependency %q; expected catalog:image:sql", value)
	}
	return parts[1], parts[2], true, nil
}

// dependencyOrder returns each dependency once, before its consumers. Unknown
// names are catalog-provided extensions; base-image entries need no image.
func dependencyOrder(target string, lookup func(string) (*extensionMetadata, error)) ([]string, error) {
	state := map[string]int{}
	var ordered []string
	var visit func(string) error
	visit = func(name string) error {
		if state[name] == 1 {
			return fmt.Errorf("extension dependency cycle at %q", name)
		}
		if state[name] == 2 {
			return nil
		}
		_, _, catalog, err := parseCatalogDependency(name)
		if err != nil {
			return err
		}
		if catalog {
			state[name] = 2
			ordered = append(ordered, name)
			return nil
		}
		dep, base, err := parseRequiredDependency(name)
		if err != nil {
			return err
		}
		if !dependencyNamePattern.MatchString(dep) {
			return fmt.Errorf("invalid dependency name %q", name)
		}
		state[name] = 1
		if !base {
			metadata, err := lookup(dep)
			if err != nil {
				return err
			}
			if metadata != nil {
				for _, child := range metadata.RequiredExtensions {
					if err := visit(child); err != nil {
						return err
					}
				}
			}
		}
		state[name] = 2
		ordered = append(ordered, name)
		return nil
	}
	if err := visit(target); err != nil {
		return nil, err
	}
	return ordered, nil
}

func dependencyLookup(ctx context.Context, source *dagger.Directory) func(string) (*extensionMetadata, error) {
	cache := map[string]*extensionMetadata{}
	return func(name string) (*extensionMetadata, error) {
		if value, found := cache[name]; found {
			return value, nil
		}
		exists, err := source.Exists(ctx, path.Join(name, metadataFile))
		if err != nil {
			return nil, err
		}
		if !exists {
			cache[name] = nil
			return nil, nil
		}
		metadata, err := parseExtensionMetadata(ctx, source.Directory(name))
		if err != nil {
			return nil, fmt.Errorf("dependency %s: %w", name, err)
		}
		cache[name] = metadata
		return metadata, nil
	}
}

// GetDependencies lists local image dependencies in build order, excluding the target.
func (m *Maintenance) GetDependencies(
	ctx context.Context,
	// Repository containing extension definitions.
	// +ignore=["dagger", ".github"]
	// +defaultPath="/"
	source *dagger.Directory,
	target string,
) (string, error) {
	lookup := dependencyLookup(ctx, source)
	metadata, err := lookup(target)
	if err != nil {
		return "", err
	}
	if metadata == nil {
		return "", fmt.Errorf("unknown target %q", target)
	}
	ordered, err := dependencyOrder(target, lookup)
	if err != nil {
		return "", err
	}
	local := []string{}
	for _, name := range ordered {
		if name == target || strings.HasPrefix(name, baseImageDependencyPrefix) || strings.HasPrefix(name, "image-sql:") || strings.HasPrefix(name, "catalog:") {
			continue
		}
		metadata, err := lookup(name)
		if err != nil {
			return "", err
		}
		if metadata != nil {
			local = append(local, name)
		}
	}
	data, err := json.Marshal(local)
	return string(data), err
}

// Testing dependencies share the parent's registry and -testing convention.
// Production/default references remain in the CNPG Extensions registry.
func dependencyImageReference(parent, dependency string) string {
	repository := strings.SplitN(parent, "@", 2)[0]
	slash := strings.LastIndex(repository, "/")
	if colon := strings.LastIndex(repository, ":"); colon > slash {
		repository = repository[:colon]
	}
	if !strings.HasSuffix(repository, "-testing") {
		return dependency
	}
	prefix := repository[:strings.LastIndex(repository, "/")+1]
	leaf := dependency[strings.LastIndex(dependency, "/")+1:]
	name, tag, found := strings.Cut(leaf, ":")
	if !found {
		return dependency
	}
	return prefix + name + "-testing:" + tag
}
