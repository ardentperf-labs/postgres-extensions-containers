#!/usr/bin/env bash
set -euo pipefail
output="$RUNNER_TEMP/sbom-check/pgagent"
mkdir -p "$output" "$RUNNER_TEMP/trivy-cache"
image=localhost:5000/pgagent-testing:4.2.3-18-bookworm
scanner=localhost:5000/cnpg-sbom-generator:check
docker buildx build --platform linux/amd64 \
  --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm \
  --build-arg PG_MAJOR=18 --build-arg EXT_VERSION=4.2.3-5.pgdg12+1 \
  --attest "type=sbom,generator=$scanner" --provenance=mode=max \
  --tag "$image" --metadata-file "$output/build.json" \
  --file .validation/PgAgent.Dockerfile --push .
docker buildx imagetools inspect "$image" --format '{{ json .SBOM.SPDX }}' > "$output/pgagent.spdx.json"
docker run --rm --entrypoint python3 --volume "$output:/results:ro" \
  "$scanner" /opt/cnpg-sbom-generator/spdx_validation.py /results/pgagent.spdx.json
for format in json table; do
  docker run --rm --volume "$output:/results" --volume "$RUNNER_TEMP/trivy-cache:/cache" \
    --env TRIVY_CACHE_DIR=/cache --env NO_COLOR=1 "$TRIVY_IMAGE" \
    sbom --scanners vuln,license --no-progress --skip-version-check \
    --format "$format" --output "/results/trivy-report.$format" /results/pgagent.spdx.json
done
