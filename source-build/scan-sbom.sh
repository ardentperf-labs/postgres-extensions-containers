#!/usr/bin/env bash
# Inspect the attached SPDX documents, independently for every native platform.
set -Eeuo pipefail
image=${1:?immutable image reference required}
output=${2:?report directory required}
shift 2
[[ "$image" == *@sha256:* ]]
mkdir -p "$output"
output=$(realpath "$output")
# renovate: datasource=docker depName=anchore/grype versioning=docker
GRYPE_IMAGE=anchore/grype:v0.121.3@sha256:13113eeceab017260370cf540e1d25442c59665fd07d1b09b66d63bb0c282887
# renovate: datasource=docker depName=anchore/grant versioning=docker
GRANT_IMAGE=anchore/grant:v0.7.1@sha256:9ccd7c26dc48ce87cd9350e29fa8da5eaaedfabb3bc2e56f6b1ce3e9e7adc4b6
platforms=("$@")
if [[ ${#platforms[@]} == 0 ]]; then platforms=(linux/amd64 linux/arm64); fi
docker buildx imagetools inspect "$image" --raw > "$output/index.json"
docker buildx imagetools inspect "$image" --format '{{json .SBOM}}' > "$output/sbom.json"
failed=0
for platform in "${platforms[@]}"; do
  case "$platform" in linux/amd64|linux/arm64) ;; *) echo 'unsupported platform' >&2; exit 1;; esac
  arch=${platform#linux/}
  jq -e --arg arch "$arch" '.manifests | any(.platform.os == "linux" and .platform.architecture == $arch)' "$output/index.json" >/dev/null
  jq --arg platform "$platform" 'if has("SPDX") then .SPDX else .[$platform].SPDX end' "$output/sbom.json" > "$output/$arch.spdx.json"
  jq -e '.spdxVersion == "SPDX-2.3" and (.packages | length > 0) and (.files | length > 0)' "$output/$arch.spdx.json" >/dev/null
  # Report all matches; findings are informational. Scanner errors still fail.
  docker run --rm -v "$output:/reports:ro" "$GRYPE_IMAGE" "sbom:/reports/$arch.spdx.json" -o json > "$output/$arch.grype.json" || failed=1
  docker run --rm -v "$output:/reports:ro" "$GRANT_IMAGE" list "/reports/$arch.spdx.json" > "$output/$arch.licenses.txt" || failed=1
done
exit "$failed"
