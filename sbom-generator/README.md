# Inspect extension SBOMs

This change publishes the generator and its optional build interface. Extension
builds continue using the existing scanner until the separate adoption change
selects an officially published generator digest. The inspection guide below
describes the resulting extension images after adoption.

CNPG Extensions images include an SPDX 2.3 software bill of materials (SBOM) for
each platform. It lists shipped files, their checksums, identifiable Debian
packages, and license evidence from the notices in `/licenses`, including copied
system libraries. Scan the PostgreSQL base image separately using its own SBOM.

## Verify the image and extract its SBOM

You need Cosign, Docker Buildx, and Trivy. This example uses the PgSphere image
published by `cnpg-extensions`, pinned to its image index digest:

```bash
IMAGE=ghcr.io/cnpg-extensions/pgsphere@sha256:54e6f0b0a9d9e4c80db8c6edcac98b451159c1fbaa91e429a92d4978f593518d

cosign verify "$IMAGE" \
  --certificate-identity='https://github.com/cnpg-extensions/postgres-extensions-containers/.github/workflows/bake_targets.yml@refs/heads/main' \
  --certificate-oidc-issuer='https://token.actions.githubusercontent.com'

docker buildx imagetools inspect "$IMAGE" \
  --format '{{ json (index .SBOM "linux/amd64").SPDX }}' \
  > pgsphere-amd64.spdx.json
```

Replace `linux/amd64` with `linux/arm64` and `pgsphere-amd64.spdx.json` with
`pgsphere-arm64.spdx.json` to inspect the ARM image. Extraction alone does not
verify the publisher. See [CloudNativePG's signature and attestation guidance](https://cloudnative-pg.io/docs/1.30/security/#image-signatures).

## Inspect and verify build provenance

BuildKit records build inputs and parameters alongside the SBOM:

```bash
docker buildx imagetools inspect "$IMAGE" \
  --format '{{ json (index .Provenance "linux/amd64").SLSA }}'
```

Separately signed SLSA provenance identifies the source repository, commit, and
workflow run. Verify that the image was built from this project's `main` branch:

```bash
slsa-verifier verify-image "$IMAGE" \
  --source-uri github.com/cnpg-extensions/postgres-extensions-containers \
  --source-branch main
```

An image built from another branch fails verification with a message such as
`expected branch 'main', got 'work/sbom-validation'`. The command exits nonzero;
it does not silently accept a different branch. Testing and production images
both receive SLSA provenance. Mirrors must preserve its separate signed
attestation as well as the image index.

## Report vulnerabilities and licenses with Trivy

```bash
trivy sbom --scanners vuln,license pgsphere-amd64.spdx.json
```

See the [example Trivy output](../examples/trivy-sbom-examples.txt) for vulnerability
and package-license tables. It is a historical local pgAgent build illustrating
the report format.

Use [`trivy sbom`](https://trivy.dev/docs/latest/target/sbom/) with the extracted
SPDX. A direct filesystem scan of the scratch image cannot recover its missing
Debian package database. Findings depend on Trivy's database and supported
package ecosystems.

### Reading license results

Syft identifies packages in the builder, but is known to miss license declarations
for many Debian packages. We therefore use ScanCode to scan the shipped `/licenses`
notices. Its findings populate SPDX file records, contribute to their owning
packages' `licenseInfoFromFiles`, and fill missing or unknown `licenseDeclared`
values.

Trivy reports package licenses. Unmatched files remain in SPDX with checksums and
scanned license evidence; their file-level findings may not appear in Trivy's
package report. `NOASSERTION` means no value was established for that field.
`LicenseRef-*` identifiers refer to `hasExtractedLicensingInfos`, with ScanCode
reference text when available. Trivy's `UNKNOWN` classification does not mean the
license expression is absent.

### Retrieve an original notice

When ScanCode provides no reference text, the original notice is still shipped
in the image. Find its path in SPDX file records using `licenseInfoInFiles`.
For example, PgSphere's shared GCC copyright notice contains an unidentified
license reference:

```bash
jq -r '.files[] |
  select(any(.licenseInfoInFiles[]?;
    contains("LicenseRef-scancode-unknown-license-reference"))) |
  .fileName' pgsphere-amd64.spdx.json
# licenses/gcc-12-base/copyright
```

Copy that notice from a stopped container; no shell inside the scratch image is
needed:

```bash
CONTAINER=$(docker create --platform linux/amd64 "$IMAGE" /unused)
docker cp "$CONTAINER:/licenses/gcc-12-base/copyright" ./gcc-12-copyright
docker rm "$CONTAINER"
```

Shared Debian notices can cover several libraries and produce broad license
expressions. Read the notice alongside the package and file evidence in SPDX.

## Generator release and test builds

`ghcr.io/cnpg-extensions/cnpg-sbom-generator:latest` identifies the checked generator
published from `main`; `:test` identifies the most recent checked manual test
publication. These are moving tags. Consumers pin a tag **and its image digest**,
so moving a tag does not silently change an extension build. `sha-<full-commit>`
tags retain individual builds; there are no major/minor releases.

### Publication

| Trigger | Result |
| --- | --- |
| Pull request touching generator code/workflow | Checks only |
| Relevant push to `main` | Publish or reuse commit image; promote the checked digest to `latest` |
| Manual dispatch, `publish=false` | Checks only |
| Manual dispatch, `publish=true` | Publish or reuse commit image; promote to `test` |

[The workflow](../.github/workflows/sbom-generator.yml) runs unit and
BuildKit/SPDX/Trivy checks on native AMD64 and ARM64 runners, publishes a
two-platform image, verifies its platform configurations and source labels, and
smoke-tests the published digest on AMD64 before promotion.

Publication is serialized. Failed checks leave aliases unchanged; manual
publication never moves `latest`. [release.py](release.py) reuses commit tags and
verifies alias digests. A dependency rebuild requires a new commit.

### Testing from a branch

For example, push a generator change on a branch named `sbom-license-update`
and publish its test image:

```bash
git switch -c sbom-license-update
# Make and commit the generator change.
git push origin sbom-license-update

gh workflow run sbom-generator.yml \
  --repo cnpg-extensions/postgres-extensions-containers \
  --ref sbom-license-update -f publish=true

gh run list --repo cnpg-extensions/postgres-extensions-containers \
  --workflow sbom-generator.yml --branch sbom-license-update --limit 1
```

Take the checked `test@sha256:…` reference from the successful run summary and pin
it in a temporary consumer branch. Run the affected extension builds before
accepting the update. Keep test pins out of stable consumers.

### Update consumers

When a generator change is merged to `main` and its checked publication advances
`latest`, [Renovate](../renovate.json) updates the stable `latest@sha256:…` consumer
pin. Digest updates are grouped and automerged after their required tests pass.
Renovate rebases an update when it falls behind `main` and waits for the checks
on that revision before merging.

Renovate also tracks the SPDX validator, grouped with ScanCode for compatibility
review, and the scanner's other dependencies. The image revision label and SPDX
creator identify the generator source commit.

To roll back, restore the previous checked consumer digest and hold updates until
fixed. Retain the corresponding commit images.
