# Generator release and test builds

Each adopting repository publishes `ghcr.io/<lowercase-owner>/cnpg-sbom-generator`.
Source commits identify builds; image digests identify their content. There are
no major/minor releases. The generator feeds the existing extension build and
signing workflows.

## Publication

| Trigger | Result |
| --- | --- |
| Pull request touching generator code/workflow | Checks only |
| Relevant push to `main` | Publish or reuse `sha-<full-commit>`; promote to `latest` if still current |
| Manual dispatch, `publish=false` | Checks only |
| Manual dispatch, `publish=true` | Publish or reuse `sha-<full-commit>`; promote to `test` |

[The workflow](../.github/workflows/sbom-generator.yml) first runs unit and
BuildKit/SPDX/Trivy integration checks on native AMD64 and ARM64 runners. It then
publishes a two-platform image, verifies both platform configurations and source
labels, and smoke-tests the published digest on AMD64 before promotion.

[release.py](release.py) reuses existing commit tags and verifies alias digests.
Publication is serialized; failed checks leave aliases unchanged, and manual
publication never moves `latest`. Commit tags are immutable by workflow convention;
consumers always pin the digest. A dependency rebuild requires a new commit.

## Try a branch

The workflow must already exist on the repository's default branch:

```bash
gh workflow run sbom-generator.yml --repo OWNER/postgres-extensions-containers \
  --ref BRANCH -f publish=true
```

Take the checked `test@sha256:...` reference from the successful run summary and
pin it in a temporary consumer branch. Run the affected extension builds before
accepting the update. Keep test pins out of stable consumers.

## Update consumers

Stable consumers use `latest@sha256:...`. [Renovate](../renovate.json) proposes
generator digest changes for review, with automerge disabled. It also tracks the
SPDX validator version, grouped with ScanCode for compatibility review, and the
scanner's other dependencies. The image revision label and SPDX creator identify
the generator source commit.

To roll back, restore the previous checked consumer digest and hold updates until
fixed. Retain the corresponding commit images. On first publication, check package
visibility and anonymous pulls; organization permission to create public packages
does not establish the visibility of an individual package.

## Adoption

The first adopter is `cnpg-extensions/postgres-extensions-containers`, with a core
contribution proposed to `cloudnative-pg/postgres-extensions-containers` in parallel.
Each repository publishes and consumes its own generator. PGRX remains downstream
and uses the optional hook; upstream acceptance does not switch downstream pins.

This development branch currently consumes the `ardentperf-labs` publication.
At adoption, change the consumer image owner and digest together with its Renovate
annotation in [bake_targets.yml](../.github/workflows/bake_targets.yml). Downstream
consumers must update their own pins as well.
