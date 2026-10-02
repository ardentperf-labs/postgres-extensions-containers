package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"path"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	"go.yaml.in/yaml/v3"

	"dagger/maintenance/internal/dagger"
)

const (
	testKubeconfigPath = "/etc/kubeconfig/config"
	testOutputPath     = "/tmp/upstream-test-results"
	testRootPath       = "/var/lib/postgresql/data/upstream-tests"
	testPGPort         = 5432

	// renovate: datasource=docker depName=alpine/kubectl versioning=docker
	testKubectlImage = "alpine/kubectl:1.37.1@sha256:7b4cc9a9ce0d064cedeb85550266c11f2b32f010ca299525518646261e4d955e"
)

var testPackageName = regexp.MustCompile(`^[a-z0-9][a-z0-9+.-]*$`)

func validateUpstreamTestBundle(ctx context.Context, testDirectory *dagger.Directory) (string, []string, error) {
	for _, name := range []string{"run.sh", "UPSTREAM", "upstream"} {
		exists, err := testDirectory.Exists(ctx, name)
		if err != nil {
			return "", nil, err
		}
		if !exists {
			return "", nil, fmt.Errorf("upstream test bundle is incomplete: test/%s is missing", name)
		}
	}

	provenance, err := testDirectory.File("UPSTREAM").Contents(ctx)
	if err != nil {
		return "", nil, fmt.Errorf("read upstream test provenance: %w", err)
	}
	if strings.TrimSpace(provenance) == "" {
		return "", nil, fmt.Errorf("upstream test provenance file test/UPSTREAM is empty")
	}

	packages, err := readRunnerPackages(ctx, testDirectory)
	if err != nil {
		return "", nil, err
	}
	return provenance, packages, nil
}

func readRunnerPackages(ctx context.Context, testDirectory *dagger.Directory) ([]string, error) {
	exists, err := testDirectory.Exists(ctx, "packages")
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, nil
	}
	contents, err := testDirectory.File("packages").Contents(ctx)
	if err != nil {
		return nil, fmt.Errorf("read test/packages: %w", err)
	}
	return parseRunnerPackages(contents)
}

func parseRunnerPackages(contents string) ([]string, error) {
	var packages []string
	seen := make(map[string]struct{})
	for lineNumber, line := range strings.Split(contents, "\n") {
		line = strings.TrimSpace(strings.SplitN(line, "#", 2)[0])
		if line == "" {
			continue
		}
		if !testPackageName.MatchString(line) {
			return nil, fmt.Errorf("invalid test-only apt package %q on line %d", line, lineNumber+1)
		}
		if _, ok := seen[line]; ok {
			continue
		}
		seen[line] = struct{}{}
		packages = append(packages, line)
	}
	return packages, nil
}

func mergeClusterSettings(base, override string, values TestingValues) (string, TestingValues, error) {
	var baseManifest map[string]any
	if err := yaml.Unmarshal([]byte(base), &baseManifest); err != nil {
		return "", values, fmt.Errorf("parse shared manifest: %w", err)
	}
	var overlayManifest map[string]any
	if err := yaml.Unmarshal([]byte(override), &overlayManifest); err != nil {
		return "", values, fmt.Errorf("parse overlay manifest: %w", err)
	}

	// A small extension overlay may declare only test-specific PostgreSQL
	// settings. Merge those settings into the external values consumed by the
	// common Cluster manifest, preserving production metadata parameters.
	if spec, ok := overlayManifest["spec"].(map[string]any); ok {
		if postgresql, ok := spec["postgresql"].(map[string]any); ok {
			if parameters, ok := postgresql["parameters"].(map[string]any); ok {
				if values.PostgresqlParameters == nil {
					values.PostgresqlParameters = make(map[string]string)
				}
				for key, value := range parameters {
					values.PostgresqlParameters[key] = fmt.Sprint(value)
				}
				delete(postgresql, "parameters")
			} else if expression, ok := postgresql["parameters"].(string); ok && expression == "($values.postgresql_parameters)" {
				delete(postgresql, "parameters")
			}
			if preload, ok := postgresql["shared_preload_libraries"].([]any); ok {
				for _, value := range preload {
					library := fmt.Sprint(value)
					if !slices.Contains(values.SharedPreloadLibraries, library) {
						values.SharedPreloadLibraries = append(values.SharedPreloadLibraries, library)
					}
				}
				delete(postgresql, "shared_preload_libraries")
			} else if expression, ok := postgresql["shared_preload_libraries"].(string); ok && expression == "($values.shared_preload_libraries)" {
				delete(postgresql, "shared_preload_libraries")
			}
			if extensions, ok := postgresql["extensions"].([]any); ok {
				if err := mergeExtensionSettings(&values, extensions); err != nil {
					return "", values, err
				}
				delete(postgresql, "extensions")
			} else if expression, ok := postgresql["extensions"].(string); ok && expression == "($values.extensions)" {
				delete(postgresql, "extensions")
			}
		}
	}
	mergeYAMLMap(baseManifest, overlayManifest)
	merged, err := yaml.Marshal(baseManifest)
	if err != nil {
		return "", values, fmt.Errorf("encode merged manifest: %w", err)
	}
	return string(merged), values, nil
}

func includeOptionalSetupFixture(
	ctx context.Context,
	sharedTestDirectory *dagger.Directory,
	extensionTestDirectory *dagger.Directory,
) (*dagger.Directory, *dagger.File, error) {
	hasSetup, err := extensionTestDirectory.Exists(ctx, "setup.yaml")
	if err != nil {
		return nil, nil, err
	}
	hasAssertion, err := extensionTestDirectory.Exists(ctx, "setup-assert.yaml")
	if err != nil {
		return nil, nil, err
	}
	if !hasSetup {
		if hasAssertion {
			return nil, nil, fmt.Errorf("test/setup-assert.yaml requires test/setup.yaml")
		}
		return sharedTestDirectory, nil, nil
	}

	setupFile := extensionTestDirectory.File("setup.yaml")
	setupContents, err := setupFile.Contents(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("read test/setup.yaml: %w", err)
	}
	if strings.Contains(setupContents, "($values.") {
		return nil, nil, fmt.Errorf("test/setup.yaml must use static Kubernetes manifests so the harness can clean up its resources")
	}

	chainFile, err := sharedTestDirectory.File("chainsaw-test.yaml").Contents(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("read shared Chainsaw test manifest: %w", err)
	}
	var chainManifest map[string]any
	if err := yaml.Unmarshal([]byte(chainFile), &chainManifest); err != nil {
		return nil, nil, fmt.Errorf("parse shared Chainsaw test manifest: %w", err)
	}
	spec, ok := chainManifest["spec"].(map[string]any)
	if !ok {
		return nil, nil, fmt.Errorf("shared Chainsaw test manifest has no spec map")
	}
	steps, ok := spec["steps"].([]any)
	if !ok {
		return nil, nil, fmt.Errorf("shared Chainsaw test manifest has no steps list")
	}
	fixtureOperations := []any{map[string]any{"apply": map[string]any{"file": "setup.yaml"}}}
	if hasAssertion {
		assertion := extensionTestDirectory.File("setup-assert.yaml")
		sharedTestDirectory = sharedTestDirectory.WithFile("setup-assert.yaml", assertion)
		fixtureOperations = append(fixtureOperations, map[string]any{"assert": map[string]any{"file": "setup-assert.yaml"}})
	}
	spec["steps"] = append([]any{map[string]any{
		"name": "Apply upstream test fixtures",
		"try":  fixtureOperations,
	}}, steps...)
	chainContents, err := yaml.Marshal(chainManifest)
	if err != nil {
		return nil, nil, fmt.Errorf("encode Chainsaw test manifest with fixtures: %w", err)
	}
	sharedTestDirectory = sharedTestDirectory.
		WithFile("setup.yaml", setupFile).
		WithNewFile("chainsaw-test.yaml", string(chainContents))
	return sharedTestDirectory, setupFile, nil
}

func mergeExtensionSettings(values *TestingValues, rawOverrides []any) error {
	for _, rawOverride := range rawOverrides {
		encoded, err := yaml.Marshal(rawOverride)
		if err != nil {
			return fmt.Errorf("encode test extension overlay: %w", err)
		}
		var override ExtensionConfiguration
		if err := yaml.Unmarshal(encoded, &override); err != nil {
			return fmt.Errorf("parse test extension overlay: %w", err)
		}
		if override.Name == "" {
			return fmt.Errorf("test extension overlay must include name")
		}
		var target *ExtensionConfiguration
		for _, extension := range values.Extensions {
			if extension != nil && extension.Name == override.Name {
				target = extension
				break
			}
		}
		if target == nil {
			return fmt.Errorf("test extension overlay %q has no matching generated extension configuration", override.Name)
		}
		if override.ImageVolumeSource.Reference != "" {
			target.ImageVolumeSource.Reference = override.ImageVolumeSource.Reference
		}
		if override.ImageVolumeSource.PullPolicy != "" {
			target.ImageVolumeSource.PullPolicy = override.ImageVolumeSource.PullPolicy
		}
		target.ExtensionControlPath = appendUnique(target.ExtensionControlPath, override.ExtensionControlPath...)
		target.DynamicLibraryPath = appendUnique(target.DynamicLibraryPath, override.DynamicLibraryPath...)
		target.LdLibraryPath = appendUnique(target.LdLibraryPath, override.LdLibraryPath...)
		target.BinPath = appendUnique(target.BinPath, override.BinPath...)
		for _, env := range override.Env {
			updated := false
			for index := range target.Env {
				if target.Env[index].Name == env.Name {
					target.Env[index] = env
					updated = true
					break
				}
			}
			if !updated {
				target.Env = append(target.Env, env)
			}
		}
	}
	return nil
}

func appendUnique(existing []string, additions ...string) []string {
	for _, addition := range additions {
		if addition != "" && !slices.Contains(existing, addition) {
			existing = append(existing, addition)
		}
	}
	return existing
}

func mergeYAMLMap(destination, overlay map[string]any) {
	for key, overlayValue := range overlay {
		destinationMap, destinationIsMap := destination[key].(map[string]any)
		overlayMap, overlayIsMap := overlayValue.(map[string]any)
		if destinationIsMap && overlayIsMap {
			mergeYAMLMap(destinationMap, overlayMap)
			continue
		}
		destination[key] = overlayValue
	}
}

func validateRunnerPackages(packages []string, targetName string, pgMajor int) error {
	for _, name := range []string{targetName, strings.ReplaceAll(targetName, "_", "-")} {
		forbidden := fmt.Sprintf("postgresql-%d-%s", pgMajor, name)
		if slices.Contains(packages, forbidden) {
			return fmt.Errorf("test/packages must not install the extension under test (%s)", forbidden)
		}
	}
	return nil
}

func decodeKubernetesSecret(encoded string) (string, error) {
	decoded, err := base64.StdEncoding.DecodeString(strings.TrimSpace(encoded))
	if err != nil {
		return "", fmt.Errorf("decode CNPG superuser secret: %w", err)
	}
	if len(decoded) == 0 {
		return "", fmt.Errorf("CNPG superuser secret is empty")
	}
	return string(decoded), nil
}

func kubectlContainer(kubeconfig *dagger.File) *dagger.Container {
	return dag.Container().From(testKubectlImage).
		WithUser("root").
		WithFile(testKubeconfigPath, kubeconfig).
		WithEnvVariable("KUBECONFIG", testKubeconfigPath).
		WithEnvVariable("CACHEBUSTER", time.Now().String())
}

func getCNPGSuperuserPassword(ctx context.Context, kubeconfig *dagger.File, clusterName string) (*dagger.Secret, error) {
	container := kubectlContainer(kubeconfig).WithExec(
		[]string{"get", "secret", clusterName + "-superuser", "--namespace=default", "-o", "jsonpath={.data.password}"},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	encoded, err := container.Stdout(ctx)
	if err != nil {
		return nil, fmt.Errorf("read CNPG test superuser secret: %w", err)
	}
	password, err := decodeKubernetesSecret(encoded)
	if err != nil {
		return nil, err
	}
	return dag.SetSecret(clusterName+"-upstream-test-password", password), nil
}

func getCNPGPrimaryPod(ctx context.Context, kubeconfig *dagger.File, clusterName string) (string, error) {
	container := kubectlContainer(kubeconfig).WithExec(
		[]string{
			"get", "pods", "--namespace=default",
			"--selector=cnpg.io/cluster=" + clusterName + ",role=primary",
			"-o", "jsonpath={.items[0].metadata.name}",
		},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	name, err := container.Stdout(ctx)
	if err != nil {
		return "", fmt.Errorf("find CNPG primary pod for %s: %w", clusterName, err)
	}
	name = strings.TrimSpace(name)
	if name == "" {
		return "", fmt.Errorf("CNPG primary pod for %s was not found", clusterName)
	}
	return name, nil
}

func copyUpstreamFixturesToCNPG(
	ctx context.Context,
	kubeconfig *dagger.File,
	podName string,
	testDirectory *dagger.Directory,
	testRoot string,
) error {
	remoteUpstream := path.Join(testRoot, "upstream")
	prepare := kubectlContainer(kubeconfig).WithExec(
		[]string{"exec", podName, "--namespace=default", "--", "mkdir", "-p", testRoot},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	if _, err := prepare.Sync(ctx); err != nil {
		return fmt.Errorf("create upstream fixture directory in CNPG pod: %w", err)
	}

	copy := kubectlContainer(kubeconfig).
		WithDirectory("/tmp/upstream-fixtures/upstream", testDirectory.Directory("upstream")).
		WithExec(
			[]string{"cp", "--namespace=default", "/tmp/upstream-fixtures/upstream", podName + ":" + remoteUpstream},
			dagger.ContainerWithExecOpts{UseEntrypoint: true},
		)
	if _, err := copy.Sync(ctx); err != nil {
		return fmt.Errorf("copy upstream fixtures into CNPG pod (requires tar in the PostgreSQL image): %w", err)
	}
	readable := kubectlContainer(kubeconfig).WithExec(
		[]string{"exec", podName, "--namespace=default", "--", "chmod", "-R", "a+rX", remoteUpstream},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	if _, err := readable.Sync(ctx); err != nil {
		return fmt.Errorf("set upstream fixtures readable in CNPG pod: %w", err)
	}
	return nil
}

func copyNativeTestBundleToCNPG(
	ctx context.Context,
	kubeconfig *dagger.File,
	podName string,
	testDirectory *dagger.Directory,
	testRoot string,
) error {
	prepare := kubectlContainer(kubeconfig).WithExec(
		[]string{
			"exec", podName, "--namespace=default", "--", "sh", "-c",
			"rm -rf \"$1\" && mkdir -p \"$(dirname \"$1\")\"",
			"prepare-upstream-test-bundle", testRoot,
		},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	if _, err := prepare.Sync(ctx); err != nil {
		return fmt.Errorf("prepare native upstream test directory in CNPG pod: %w", err)
	}

	copy := kubectlContainer(kubeconfig).
		WithDirectory("/tmp/upstream-fixtures/test", testDirectory).
		WithExec(
			[]string{"cp", "--namespace=default", "/tmp/upstream-fixtures/test", podName + ":" + testRoot},
			dagger.ContainerWithExecOpts{UseEntrypoint: true},
		)
	if _, err := copy.Sync(ctx); err != nil {
		return fmt.Errorf("copy native upstream test bundle into CNPG pod (requires tar in the PostgreSQL image): %w", err)
	}
	readable := kubectlContainer(kubeconfig).WithExec(
		[]string{
			"exec", podName, "--namespace=default", "--", "chmod", "-R", "u+rwX,a+rX", testRoot,
		},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	if _, err := readable.Sync(ctx); err != nil {
		return fmt.Errorf("set native upstream test bundle permissions in CNPG pod: %w", err)
	}
	return nil
}

func nativeTestCommandArgs(podName string, testRoot string, pgMajor int) []string {
	harnessDirectory := path.Join(testRoot, ".harness")
	outputDirectory := path.Join(harnessDirectory, "results")
	return []string{
		"exec", podName, "--namespace=default", "--", "env",
		"PGHOST=/controller/run",
		"PGPORT=5432",
		"PGUSER=postgres",
		"PGDATABASE=postgres",
		"PGPASSWORD=",
		"PG_MAJOR=" + strconv.Itoa(pgMajor),
		"PG_REGRESS=" + path.Join(harnessDirectory, "bin", "pg_regress"),
		"PG_ISOLATION_REGRESS=" + path.Join(harnessDirectory, "bin", "pg_isolation_regress"),
		"TEST_OUTPUT=" + outputDirectory,
		"PG_EXTENSION_PAYLOAD=" + path.Join(harnessDirectory, "payload"),
		"sh", "-c", `
set -eu
mkdir -p "$TEST_OUTPUT"
dropdb --if-exists --maintenance-db=postgres contrib_regression
createdb --maintenance-db=postgres contrib_regression
export PGDATABASE=contrib_regression
export PATH="$PG_EXTENSION_PAYLOAD/bin:$PG_EXTENSION_PAYLOAD/usr/bin:$PATH"
export LD_LIBRARY_PATH="$PG_EXTENSION_PAYLOAD/system:$PG_EXTENSION_PAYLOAD/lib:${LD_LIBRARY_PATH:-}"
cd "$1"
exec sh ./run.sh
`,
		"run-upstream-test-suite", testRoot,
	}
}

func runTestArtifactSummary(ctx context.Context, result *dagger.Container, status int) string {
	var summary strings.Builder
	appendTestCommandOutput(ctx, &summary, result)

	// Read only the useful text reports and cap each one before it crosses the
	// Dagger boundary. Some suites can leave large temporary result files.
	artifactContainer := result.WithExec([]string{"sh", "-c", `
set -eu
for file in "$TEST_OUTPUT"/*.diffs "$TEST_OUTPUT"/regression.out "$TEST_OUTPUT"/*.log; do
  [ -f "$file" ] || continue
  printf '\n--- %s ---\n' "$file"
  head -c 32768 "$file"
  printf '\n'
done
`})
	artifacts, artifactsErr := artifactContainer.Stdout(ctx)
	if artifactsErr == nil && strings.TrimSpace(artifacts) != "" {
		fmt.Fprintf(&summary, "\n--- upstream result files (exit %d) ---\n%s", status, limitTestOutput(artifacts))
	}
	return summary.String()
}

func runNativeTestArtifactSummary(
	ctx context.Context,
	kubeconfig *dagger.File,
	podName string,
	result *dagger.Container,
	outputDirectory string,
	status int,
) string {
	var summary strings.Builder
	appendTestCommandOutput(ctx, &summary, result)
	artifactContainer := kubectlContainer(kubeconfig).WithExec(
		[]string{
			"exec", podName, "--namespace=default", "--", "sh", "-c", `
set -eu
for file in "$1"/*.diffs "$1"/regression.out "$1"/*.log; do
  [ -f "$file" ] || continue
  printf '\n--- %s ---\n' "$file"
  head -c 32768 "$file"
  printf '\n'
done
`,
			"collect-upstream-test-results", outputDirectory,
		},
		dagger.ContainerWithExecOpts{UseEntrypoint: true},
	)
	artifacts, artifactsErr := artifactContainer.Stdout(ctx)
	if artifactsErr == nil && strings.TrimSpace(artifacts) != "" {
		fmt.Fprintf(&summary, "\n--- upstream result files (exit %d) ---\n%s", status, limitTestOutput(artifacts))
	}
	return summary.String()
}

func appendTestCommandOutput(ctx context.Context, summary *strings.Builder, result *dagger.Container) {
	stdout, stdoutErr := result.Stdout(ctx)
	if stdoutErr == nil && strings.TrimSpace(stdout) != "" {
		fmt.Fprintf(summary, "\n--- upstream test stdout ---\n%s", limitTestOutput(stdout))
	}
	stderr, stderrErr := result.Stderr(ctx)
	if stderrErr == nil && strings.TrimSpace(stderr) != "" {
		fmt.Fprintf(summary, "\n--- upstream test stderr ---\n%s", limitTestOutput(stderr))
	}
}

func limitTestOutput(contents string) string {
	const maxChars = 32 * 1024
	if len(contents) <= maxChars {
		return contents
	}
	return contents[:maxChars] + "\n[output truncated]"
}

func deleteTestingFixtures(ctx context.Context, kubeconfig *dagger.File, setupFile *dagger.File) error {
	if setupFile == nil {
		return nil
	}
	container := kubectlContainer(kubeconfig).
		WithFile("/tmp/upstream-test-setup.yaml", setupFile).
		WithExec(
			[]string{
				"delete", "--namespace=default", "--ignore-not-found=true", "--wait=true",
				"-f", "/tmp/upstream-test-setup.yaml",
			},
			dagger.ContainerWithExecOpts{UseEntrypoint: true},
		)
	if _, err := container.Sync(ctx); err != nil {
		return fmt.Errorf("delete temporary upstream test fixtures: %w", err)
	}
	return nil
}
