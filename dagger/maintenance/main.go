// This dagger module provides maintenance utilities for CloudNativePG
// Postgres extension container images tasks

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"maps"
	"path"
	"regexp"
	"slices"
	"sort"
	"strconv"
	"strings"
	"text/template"
	"time"

	"go.yaml.in/yaml/v3"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"

	"dagger/maintenance/internal/dagger"
)

type Maintenance struct{}

// Updates the OS dependencies in the system-libs directory for the specified extension(s)
func (m *Maintenance) UpdateOSLibs(
	ctx context.Context,
	// The source directory containing the extension folders. Defaults to the current directory
	// +ignore=["dagger", ".github"]
	// +defaultPath="/"
	source *dagger.Directory,
	// The target extension to update OS libs for. Defaults to "all".
	// +default="all"
	target string,
) (*dagger.Directory, error) {
	extDir := source
	if target != "all" {
		extDir = source.Filter(dagger.DirectoryFilterOpts{
			Include: []string{path.Join(target, "**")},
		})
		hasMetadataFile, err := extDir.Exists(ctx, path.Join(target, metadataFile))
		if err != nil {
			return nil, err
		}
		if !hasMetadataFile {
			return nil, fmt.Errorf("not a valid target, metadata.hcl file is missing. Target: %s", target)
		}
	}

	targetExtensions, err := getExtensions(ctx, extDir, WithOSLibsFilter())
	if err != nil {
		return source, err
	}
	if len(targetExtensions) == 0 && target != "all" {
		return nil, fmt.Errorf("the target %q does not require OS Libs update", target)
	}

	const systemLibsDir = "system-libs"
	includeDirs := make([]string, 0, len(targetExtensions))

	for dir, extension := range targetExtensions {
		targetDir := path.Join(dir, systemLibsDir)
		includeDirs = append(includeDirs, targetDir)

		matrix, err := parseBuildMatrix(ctx, source, dir)
		if err != nil {
			return nil, err
		}

		files := make([]*dagger.File, 0, len(matrix.Combinations))
		for _, combo := range matrix.Combinations {
			file, err := updateOSLibsOnTarget(
				ctx,
				extension,
				combo.Distribution,
				combo.MajorVersion,
			)
			if err != nil {
				return source, err
			}
			files = append(files, file)
		}
		source = source.WithFiles(targetDir, files)
	}

	return source.Filter(dagger.DirectoryFilterOpts{
		Include: includeDirs,
	}), nil
}

// Retrieves a list in JSON format of the extensions requiring OS libs updates
func (m *Maintenance) GetOSLibsTargets(
	ctx context.Context,
	// The source directory containing the extension folders. Defaults to the current directory
	// +ignore=["dagger", ".github"]
	// +defaultPath="/"
	source *dagger.Directory,
) (string, error) {
	targetExtensions, err := getExtensions(ctx, source, WithOSLibsFilter())
	if err != nil {
		return "", err
	}
	jsonTargets, err := json.Marshal(slices.Sorted(maps.Keys(targetExtensions)))
	if err != nil {
		return "", err
	}

	return string(jsonTargets), nil
}

// Retrieves a list in JSON format of the extensions
func (m *Maintenance) GetTargets(
	ctx context.Context,
	// The source directory containing the extension folders. Defaults to the current directory
	// +ignore=["dagger", ".github"]
	// +defaultPath="/"
	source *dagger.Directory,
) (string, error) {
	targetExtensions, err := getExtensions(ctx, source)
	if err != nil {
		return "", err
	}
	jsonTargets, err := json.Marshal(slices.Sorted(maps.Keys(targetExtensions)))
	if err != nil {
		return "", err
	}

	return string(jsonTargets), nil
}

// Generates Chainsaw's testing external values in YAML format
func (m *Maintenance) GenerateTestingValues(
	ctx context.Context,
	// The source directory containing the extension folders. Defaults to the current directory
	// +ignore=["dagger", ".github"]
	// +defaultPath="/"
	source *dagger.Directory,
	// The target extension to generate values for
	target string,
	// URL reference to the extension image to test [REPOSITORY[:TAG]]
	// +optional
	extensionImage string,
	// Registry username for authentication (optional)
	// +optional
	registryUsername string,
	// Registry password or token for authentication (optional)
	// +optional
	registryPassword *dagger.Secret,
) (*dagger.File, error) {
	metadata, err := parseExtensionMetadata(ctx, source.Directory(target))
	if err != nil {
		return nil, err
	}

	targetExtensionImage := extensionImage
	if targetExtensionImage == "" {
		targetExtensionImage, err = getDefaultExtensionImage(metadata)
		if err != nil {
			return nil, err
		}
	}

	annotations, err := getImageAnnotations(ctx, targetExtensionImage, registryUsername, registryPassword)
	if err != nil {
		return nil, err
	}

	pgImage := annotations[AnnotationImageBaseName]
	if pgImage == "" {
		return nil, fmt.Errorf(
			"extension image %s doesn't have an %q annotation or its value is empty",
			targetExtensionImage, AnnotationImageBaseName)
	}

	distribution, pgMajor, err := parseImageCoordinates(annotations)
	if err != nil {
		return nil, fmt.Errorf("extension image %s: %w", targetExtensionImage, err)
	}

	locator := imageLocator{
		ExtensionImage: targetExtensionImage,
		Distribution:   distribution,
		PgMajor:        pgMajor,
	}

	testDependencies, err := readTestDependencies(ctx, source.Directory(target), distribution)
	if err != nil {
		return nil, err
	}
	extensions, err := generateTestingValuesExtensions(ctx, source, metadata, locator, testDependencies)
	if err != nil {
		return nil, err
	}

	// Build values.yaml content
	values := TestingValues{
		Name:                   metadata.Name,
		SharedPreloadLibraries: metadata.SharedPreloadLibraries,
		PostgresqlParameters:   metadata.PostgresqlParameters,
		PgImage:                pgImage,
		PgMajor:                pgMajor,
		Distribution:           distribution,
		Extensions:             extensions,
	}
	valuesYaml, err := yaml.Marshal(values)
	if err != nil {
		return nil, err
	}

	result := dag.File("values.yaml", string(valuesYaml))

	return result, nil
}

// Scaffolds a new Postgres extension directory structure
func (m *Maintenance) Create(
	ctx context.Context,
	// The source directory containing the extension template files
	// +defaultPath="/templates"
	templatesDir *dagger.Directory,
	// The name of the extension
	name string,
	// The Postgres major versions the extension is supported for
	// +default=["18"]
	versions []string,
	// The Debian distributions the extension is supported for
	// +default=["trixie","bookworm"]
	distros []string,
	// The Debian package name for the extension. If the package name contains
	// the postgres version, it can be templated using the "%version%" placeholder.
	//  (default "postgresql-%version%-<name>")
	// +optional
	packageName string,
) (*dagger.Directory, error) {
	// Validate name parameter
	if name == "" {
		return nil, fmt.Errorf("name cannot be empty")
	}
	// Validate name contains only lowercase alphanumeric characters, hyphens, and underscores
	validNamePattern := regexp.MustCompile(`^[a-z0-9_-]+$`)
	if !validNamePattern.MatchString(name) {
		return nil, fmt.Errorf(
			"invalid extension name: %s (must contain only lowercase alphanumeric characters, hyphens, and underscores)",
			name,
		)
	}

	// Validate versions array is not empty
	if len(versions) == 0 {
		return nil, fmt.Errorf("versions array cannot be empty")
	}

	// Validate distros array is not empty
	if len(distros) == 0 {
		return nil, fmt.Errorf("distros array cannot be empty")
	}

	// Validate template files exist
	var templateFiles = []string{
		"metadata.hcl",
		"Dockerfile",
		"README.md",
	}
	for _, fileName := range templateFiles {
		tmplFile := templatesDir.File(fileName + ".tmpl")
		if _, err := tmplFile.Contents(ctx); err != nil {
			return nil, fmt.Errorf("required template file %s.tmpl not found: %w", fileName, err)
		}
	}

	extDir := dag.Directory()

	type Extension struct {
		Name           string
		Versions       []string
		Distros        []string
		Package        string
		DefaultVersion int
		DefaultDistro  string
	}

	if packageName == "" {
		packageName = "postgresql-%version%-" + name
	}

	extension := Extension{
		Name:           name,
		Versions:       versions,
		Distros:        distros,
		Package:        packageName,
		DefaultVersion: DefaultPgMajor,
		DefaultDistro:  DefaultDistribution,
	}

	toTitle := func(s string) string {
		return cases.Title(language.English).String(s)
	}

	funcMap := template.FuncMap{
		"replaceAll": strings.ReplaceAll,
		"toTitle":    toTitle,
	}

	executeTemplate := func(fileName string) error {
		tmplFile := templatesDir.File(fileName + ".tmpl")
		tmplContent, err := tmplFile.Contents(ctx)
		if err != nil {
			return fmt.Errorf("failed to read template file %s.tmpl: %w", fileName, err)
		}
		tmpl, err := template.New(fileName).Funcs(funcMap).Parse(tmplContent)
		if err != nil {
			return fmt.Errorf("failed to parse template %s.tmpl: %w", fileName, err)
		}
		buf := &bytes.Buffer{}
		if err := tmpl.Execute(buf, extension); err != nil {
			return fmt.Errorf("failed to execute template %s.tmpl: %w", fileName, err)
		}
		extDir = extDir.WithNewFile(fileName, buf.String())
		return nil
	}

	for _, fileName := range templateFiles {
		if err := executeTemplate(fileName); err != nil {
			return nil, err
		}
	}

	return extDir, nil
}

// Tests the specified target with its vendored upstream test suite.
func (m *Maintenance) Test(
	ctx context.Context,
	// The source directory containing the extension folders. Defaults to the current directory
	// +ignore=["dagger", ".github"]
	// +defaultPath="/"
	source *dagger.Directory,
	// Kubeconfig to connect to the target K8s
	// +required
	kubeconfig *dagger.File,
	// The target extension to test
	// +default="all"
	target string,
	// Container image to use to run the shared Chainsaw Cluster setup
	// renovate: datasource=docker depName=kyverno/chainsaw packageName=ghcr.io/kyverno/chainsaw versioning=docker
	// +default="ghcr.io/kyverno/chainsaw:v0.2.15@sha256:527f3be2b9ec0580cb0bc84540a0fee99406b011c24ae3a30953e525af60809d"
	chainsawImage string,
	// Additional arguments to pass to Chainsaw test command
	// +optional
	extraArgs []string,
) (returnErr error) {
	extDir := source
	if target != "all" {
		extDir = source.Filter(dagger.DirectoryFilterOpts{
			Include: []string{path.Join(target, "**"), "test"},
		})
		hasMetadataFile, err := extDir.Exists(ctx, path.Join(target, metadataFile))
		if err != nil {
			return err
		}
		if !hasMetadataFile {
			return fmt.Errorf("not a valid target, metadata.hcl file is missing. Target: %s", target)
		}
	}

	targetExtensions, err := extensionsDirectories(ctx, extDir)
	if err != nil {
		return err
	}

	const valuesFile = "values.yaml"
	keepCluster := slices.Contains(extraArgs, "--skip-delete")
	var clustersToDelete []string
	var fixturesToDelete []*dagger.File
	defer func() {
		for _, setupFile := range fixturesToDelete {
			if err := deleteTestingFixtures(ctx, kubeconfig, setupFile); err != nil {
				returnErr = errors.Join(returnErr, err)
			}
		}
		if keepCluster {
			return
		}
		for _, clusterName := range clustersToDelete {
			if err := deleteTestingCluster(ctx, kubeconfig, clusterName); err != nil {
				returnErr = errors.Join(returnErr, err)
			}
		}
	}()

	for _, targetExtension := range targetExtensions {
		extName, err := targetExtension.Name(ctx)
		if err != nil {
			return err
		}

		hasValues, err := targetExtension.Exists(ctx, valuesFile)
		if err != nil {
			return err
		}
		if !hasValues {
			return fmt.Errorf("cannot execute tests for extension %q, values.yaml file is missing", target)
		}
		valuesYAML, err := targetExtension.File(valuesFile).Contents(ctx)
		if err != nil {
			return fmt.Errorf("read test values for %s: %w", extName, err)
		}
		var values TestingValues
		if err := yaml.Unmarshal([]byte(valuesYAML), &values); err != nil {
			return fmt.Errorf("parse test values for %s: %w", extName, err)
		}
		if values.Name == "" || values.PgImage == "" || values.PgMajor <= 0 || values.Distribution == "" {
			return fmt.Errorf("test values for %s must declare name, pg_image, pg_major, and distribution", extName)
		}

		extensionTestDirectory := targetExtension.Directory("test")
		provenance, runnerPackages, err := validateUpstreamTestBundle(ctx, extensionTestDirectory)
		if err != nil {
			return fmt.Errorf("extension %s: %w", extName, err)
		}
		if err := validateRunnerPackages(runnerPackages, extName, values.PgMajor); err != nil {
			return fmt.Errorf("extension %s: %w", extName, err)
		}
		runOnServer, err := extensionTestDirectory.Exists(ctx, "run-on-server")
		if err != nil {
			return err
		}
		if runOnServer && len(runnerPackages) > 0 {
			return fmt.Errorf("extension %s: test/run-on-server cannot use runner-only test/packages; use the remote runner for suites needing extra tools", extName)
		}
		if len(values.Extensions) == 0 || values.Extensions[0] == nil || values.Extensions[0].ImageVolumeSource.Reference == "" {
			return fmt.Errorf("test values for %s do not reference the built extension image", extName)
		}
		targetImage := values.Extensions[0].ImageVolumeSource.Reference
		testRoot := path.Join(testRootPath, extName, "test")

		// Chainsaw owns only the setup/readiness gate. The target Cluster is
		// retained while the upstream suite runs and removed when Test returns.
		sharedTestDirectory := source.Directory("test")
		clusterOverrideExists, err := extensionTestDirectory.Exists(ctx, "cluster.yaml")
		if err != nil {
			return err
		}
		if clusterOverrideExists {
			baseCluster, err := sharedTestDirectory.File("cluster.yaml").Contents(ctx)
			if err != nil {
				return fmt.Errorf("read shared Cluster test manifest: %w", err)
			}
			overrideCluster, err := extensionTestDirectory.File("cluster.yaml").Contents(ctx)
			if err != nil {
				return fmt.Errorf("read %s Cluster test overlay: %w", extName, err)
			}
			mergedCluster, mergedValues, err := mergeClusterSettings(baseCluster, overrideCluster, values)
			if err != nil {
				return fmt.Errorf("merge %s Cluster test overlay: %w", extName, err)
			}
			sharedTestDirectory = sharedTestDirectory.WithNewFile("cluster.yaml", mergedCluster)
			values = mergedValues
		}
		sharedTestDirectory, setupFile, err := includeOptionalSetupFixture(ctx, sharedTestDirectory, extensionTestDirectory)
		if err != nil {
			return fmt.Errorf("extension %s: %w", extName, err)
		}
		if setupFile != nil {
			fixturesToDelete = append(fixturesToDelete, setupFile)
		}
		valuesYAMLForTest, err := yaml.Marshal(values)
		if err != nil {
			return fmt.Errorf("encode test values for %s: %w", extName, err)
		}
		targetForTest := targetExtension.WithNewFile(valuesFile, string(valuesYAMLForTest))

		if !slices.Contains(clustersToDelete, values.Name) {
			clustersToDelete = append(clustersToDelete, values.Name)
		}

		ctr := dag.Container().From(chainsawImage).
			WithUser("root").
			WithWorkdir("e2e").
			WithEnvVariable("CACHEBUSTER", time.Now().String()).
			WithDirectory("test", sharedTestDirectory).
			WithDirectory(extName, targetForTest).
			WithFile(testKubeconfigPath, kubeconfig).
			WithEnvVariable("KUBECONFIG", testKubeconfigPath)

		chainsawTestArgs := []string{
			"test",
			"./test",
			"--values", path.Join(extName, valuesFile),
			"--namespace=default",
		}
		chainsawTestArgs = append(chainsawTestArgs, extraArgs...)
		if !keepCluster {
			chainsawTestArgs = append(chainsawTestArgs, "--skip-delete")
		}

		_, err = ctr.WithExec(
			chainsawTestArgs,
			dagger.ContainerWithExecOpts{
				UseEntrypoint: true,
			}).
			Sync(ctx)

		if err != nil {
			return err
		}
		podName, err := getCNPGPrimaryPod(ctx, kubeconfig, values.Name)
		if err != nil {
			return err
		}
		allPackages := []string{
			"build-essential", "ca-certificates", "make",
			"postgresql-client-" + strconv.Itoa(values.PgMajor),
			"postgresql-server-dev-" + strconv.Itoa(values.PgMajor),
		}
		allPackages = append(allPackages, runnerPackages...)
		allPackages = slices.Compact(allPackages)

		toolRunner := dag.Container().From(values.PgImage).
			WithUser("root").
			WithExec([]string{"apt-get", "update"}).
			WithExec(append([]string{"apt-get", "install", "-y", "--no-install-recommends"}, allPackages...))

		regressPath := fmt.Sprintf("/usr/lib/postgresql/%d/lib/pgxs/src/test/regress/pg_regress", values.PgMajor)
		isolationRegressPath := fmt.Sprintf("/usr/lib/postgresql/%d/lib/pgxs/src/test/isolation/pg_isolation_regress", values.PgMajor)
		var testResult *dagger.Container
		if runOnServer {
			testUtilities := dag.Directory().
				WithFile("pg_regress", toolRunner.File(regressPath), dagger.DirectoryWithFileOpts{Permissions: 0o755}).
				WithFile("pg_isolation_regress", toolRunner.File(isolationRegressPath), dagger.DirectoryWithFileOpts{Permissions: 0o755})
			nativeTestDirectory := extensionTestDirectory.WithDirectory(path.Join(".harness", "bin"), testUtilities)
			targetPayload := dag.Container().From(targetImage).Rootfs()
			nativePayload := dag.Directory()
			hasNativePayload := false
			for _, payloadPath := range []string{"bin", "usr/bin", "system", "lib"} {
				exists, err := targetPayload.Exists(ctx, payloadPath)
				if err != nil {
					return fmt.Errorf("inspect target image payload directory %s: %w", payloadPath, err)
				}
				if exists {
					nativePayload = nativePayload.WithDirectory(payloadPath, targetPayload.Directory(payloadPath))
					hasNativePayload = true
				}
			}
			if hasNativePayload {
				nativeTestDirectory = nativeTestDirectory.WithDirectory(path.Join(".harness", "payload"), nativePayload)
			}
			if err := copyNativeTestBundleToCNPG(ctx, kubeconfig, podName, nativeTestDirectory, testRoot); err != nil {
				return err
			}
			testResult, err = kubectlContainer(kubeconfig).WithExec(
				nativeTestCommandArgs(podName, testRoot, values.PgMajor),
				dagger.ContainerWithExecOpts{UseEntrypoint: true, Expect: dagger.ReturnTypeAny},
			).Sync(ctx)
		} else {
			if err := copyUpstreamFixturesToCNPG(ctx, kubeconfig, podName, extensionTestDirectory, testRoot); err != nil {
				return err
			}
			password, err := getCNPGSuperuserPassword(ctx, kubeconfig, values.Name)
			if err != nil {
				return err
			}
			portForward := kubectlContainer(kubeconfig).
				WithExposedPort(testPGPort).
				AsService(dagger.ContainerAsServiceOpts{
					Args: []string{
						"port-forward", "--address=0.0.0.0", "--namespace=default",
						"service/" + values.Name + "-rw", fmt.Sprintf("%d:%d", testPGPort, testPGPort),
					},
					UseEntrypoint: true,
				})

			runner := toolRunner.
				WithWorkdir(testRoot).
				WithDirectory(testRoot, extensionTestDirectory).
				WithDirectory(path.Join(testRoot, "payload"), dag.Container().From(targetImage).Rootfs()).
				WithExec([]string{"chown", "-R", "postgres:postgres", testRoot}).
				WithUser("postgres").
				WithExec([]string{"mkdir", "-p", testOutputPath}).
				WithEnvVariable("PATH", path.Join(testRoot, "payload", "bin")+":$PATH", dagger.ContainerWithEnvVariableOpts{Expand: true}).
				WithEnvVariable("LD_LIBRARY_PATH", path.Join(testRoot, "payload", "system")+":"+path.Join(testRoot, "payload", "lib")+":$LD_LIBRARY_PATH", dagger.ContainerWithEnvVariableOpts{Expand: true}).
				WithEnvVariable("PGHOST", "postgres").
				WithEnvVariable("PGPORT", strconv.Itoa(testPGPort)).
				WithEnvVariable("PGUSER", "postgres").
				WithEnvVariable("PGDATABASE", "contrib_regression").
				WithEnvVariable("PG_MAJOR", strconv.Itoa(values.PgMajor)).
				WithEnvVariable("PG_REGRESS", regressPath).
				WithEnvVariable("PG_ISOLATION_REGRESS", isolationRegressPath).
				WithEnvVariable("TEST_OUTPUT", testOutputPath).
				WithEnvVariable("PG_EXTENSION_PAYLOAD", path.Join(testRoot, "payload")).
				WithEnvVariable("PGSSLMODE", "disable").
				WithEnvVariable("PGGSSENCMODE", "disable").
				WithEnvVariable("PGSSLROOTCERT", "").
				WithSecretVariable("PGPASSWORD", password).
				WithServiceBinding("postgres", portForward).
				WithEnvVariable("CACHEBUSTER", time.Now().String()).
				WithExec([]string{"dropdb", "--if-exists", "--maintenance-db=postgres", "contrib_regression"}).
				WithExec([]string{"createdb", "--maintenance-db=postgres", "contrib_regression"})

			testResult, err = runner.WithExec(
				[]string{"sh", "./run.sh"},
				dagger.ContainerWithExecOpts{Expect: dagger.ReturnTypeAny},
			).Sync(ctx)
		}
		if err != nil {
			return fmt.Errorf("execute upstream test suite for %s (%s): %w", extName, provenance, err)
		}
		exitCode, err := testResult.ExitCode(ctx)
		if err != nil {
			return fmt.Errorf("read upstream test status for %s: %w", extName, err)
		}
		if exitCode != 0 {
			var detail string
			if runOnServer {
				detail = runNativeTestArtifactSummary(ctx, kubeconfig, podName, testResult, path.Join(testRoot, ".harness", "results"), exitCode)
			} else {
				detail = runTestArtifactSummary(ctx, testResult, exitCode)
			}
			if exitCode == 77 {
				return fmt.Errorf("upstream test suite for %s is unsupported (exit 77); %s%s", extName, provenance, detail)
			}
			return fmt.Errorf("upstream test suite for %s failed with exit status %d; %s%s", extName, exitCode, provenance, detail)
		}
		if setupFile != nil {
			if err := deleteTestingFixtures(ctx, kubeconfig, setupFile); err != nil {
				return err
			}
			fixturesToDelete = slices.DeleteFunc(fixturesToDelete, func(file *dagger.File) bool { return file == setupFile })
		}
		if !keepCluster {
			if err := deleteTestingCluster(ctx, kubeconfig, values.Name); err != nil {
				return err
			}
			clustersToDelete = slices.DeleteFunc(clustersToDelete, func(name string) bool { return name == values.Name })
		}
	}

	return nil
}

func deleteTestingCluster(ctx context.Context, kubeconfig *dagger.File, clusterName string) error {
	if clusterName == "" {
		return nil
	}
	container := kubectlContainer(kubeconfig).WithExec(
		[]string{"delete", "cluster", clusterName, "--namespace=default", "--ignore-not-found=true", "--wait=true"},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	if _, err := container.Sync(ctx); err != nil {
		return fmt.Errorf("delete temporary CNPG Cluster %s: %w", clusterName, err)
	}
	return nil
}

// Generate extension's ClusterImageCatalogs starting from a base set of catalogs
func (m *Maintenance) GenerateCatalogs(
	ctx context.Context,
	// The source directory containing the extension folders. Defaults to the current directory
	// +ignore=["dagger", ".github"]
	// +defaultPath="/"
	source *dagger.Directory,
	// The directory containing the starting catalogs. Defaults to "/image-catalogs"
	// +defaultPath="/image-catalogs"
	catalogsDir *dagger.Directory,
) (*dagger.Directory, error) {
	outDir := dag.Directory()

	catalogs, err := getMinimalCatalogs(ctx, catalogsDir)
	if err != nil {
		return nil, fmt.Errorf("while retrieving base catalogs: %w", err)
	}

	targetExtensions, err := getExtensions(ctx, source)
	if err != nil {
		return nil, fmt.Errorf("while retrieving extensions: %w", err)
	}
	if len(targetExtensions) == 0 {
		return nil, fmt.Errorf("no extensions found in source directory")
	}
	if len(catalogs) == 0 {
		return nil, fmt.Errorf("no catalogs matched the selection criteria")
	}

	metadataByDir := make(map[string]*extensionMetadata, len(targetExtensions))
	for dir, extension := range targetExtensions {
		metadata, err := parseExtensionMetadata(ctx, source.Directory(dir))
		if err != nil {
			return nil, fmt.Errorf("while parsing extension %s metadata: %w", extension, err)
		}
		metadataByDir[dir] = metadata
	}

	for _, catalog := range catalogs {
		catalogOS, ok := catalog.Metadata.Labels[LabelImageOS]
		if !ok {
			return nil, fmt.Errorf("while retrieving OS for %q catalog", catalog.Metadata.Name)
		}

		for dir, extension := range targetExtensions {
			metadata := metadataByDir[dir]
			matrix := buildMatrixFromMetadata(metadata)
			if !matrix.hasDistribution(catalogOS) {
				continue
			}

			for i := range catalog.Spec.Images {
				img := &catalog.Spec.Images[i]
				if !matrix.contains(catalogOS, strconv.Itoa(img.Major)) {
					continue
				}

				targetExtensionImage, err := getExtensionImageWithTimestamp(metadata, catalogOS, img.Major)
				if err != nil {
					return nil, fmt.Errorf("while retrieving extension %s image: %w", extension, err)
				}

				extensionsConfig := ExtensionConfiguration{
					Name: metadata.Name,
					ImageVolumeSource: ImageVolumeSource{
						Reference: targetExtensionImage,
					},
					ExtensionControlPath: metadata.ExtensionControlPath,
					DynamicLibraryPath:   metadata.DynamicLibraryPath,
					LdLibraryPath:        metadata.LdLibraryPath,
					BinPath:              metadata.BinPath,
					Env:                  envMapToSlice(metadata.Env),
				}

				img.Extensions = append(img.Extensions, extensionsConfig)

				// Sort extensions by name
				sort.Slice(img.Extensions, func(i, j int) bool {
					return img.Extensions[i].Name < img.Extensions[j].Name
				})
			}
		}

		outDir, err = writeCatalogToDir(catalog, outDir)
		if err != nil {
			return nil, fmt.Errorf("while writing catalog %s: %w", catalog.Metadata.Name, err)
		}
	}

	return outDir, nil
}
