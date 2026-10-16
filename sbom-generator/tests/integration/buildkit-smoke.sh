#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 GENERATOR_IMAGE OUTPUT_DIRECTORY [FIXTURE_TAG]" >&2
  exit 2
fi

generator_image=$1
artifact_dir=$(mkdir -p "$2" && cd "$2" && pwd)
fixture_tag=${3:-"manual-$(date -u +%Y%m%d%H%M%S)-$$"}
registry=${SBOM_SMOKE_REGISTRY:-localhost:5000}
trivy_image=${TRIVY_IMAGE:-}
python=${PYTHON:-python3}
builder=${BUILDX_BUILDER:-}
platform=${SBOM_SMOKE_PLATFORM:-linux/amd64}
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../../.." && pwd)
fixture_context="$script_dir/fixture"
fixture_image="$registry/cnpg-sbom-smoke:$fixture_tag"

for command in docker "$python"; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "required command is unavailable: $command" >&2
    exit 1
  fi
done
if [[ -z "$trivy_image" ]]; then
  echo "TRIVY_IMAGE must name a pinned Trivy container image" >&2
  exit 1
fi
docker buildx version >/dev/null

build_args=(buildx build --platform "$platform" --tag "$fixture_image"
  --attest "type=sbom,generator=$generator_image"
  --metadata-file "$artifact_dir/build-metadata.json"
  --push)
if [[ -n "$builder" ]]; then
  build_args+=(--builder "$builder")
fi
build_args+=("$fixture_context")
docker "${build_args[@]}"

# Buildx exposes the SBOM attached to the pushed fixture image as platform
# metadata. The fixture itself is pushed only to the disposable local registry.
docker buildx imagetools inspect "$fixture_image" \
  --format '{{ json .SBOM.SPDX }}' \
  > "$artifact_dir/fixture.spdx.json"
if [[ ! -s "$artifact_dir/fixture.spdx.json" ]]; then
  echo "BuildKit did not export an SPDX predicate for $fixture_image" >&2
  exit 1
fi

"$python" "$repo_root/sbom-generator/spdx_validation.py" \
  "$artifact_dir/fixture.spdx.json"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env TRIVY_CACHE_DIR=/tmp/trivy-cache \
  --volume "$artifact_dir:/results" \
  "$trivy_image" \
  sbom --scanners license --format json \
  --output /results/trivy-license-report.json \
  /results/fixture.spdx.json

"$python" "$script_dir/check_buildkit_smoke.py" \
  "$artifact_dir/fixture.spdx.json" \
  "$artifact_dir/trivy-license-report.json"

echo "Fixture image: $fixture_image"
echo "Artifacts: $artifact_dir"
