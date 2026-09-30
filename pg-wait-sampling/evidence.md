# Package and dependency evidence

Checked 2026-09-29 in disposable `ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie` and `18-minimal-bookworm` containers. `apt search` and `apt-cache policy` report the selected candidate from `https://apt.postgresql.org/pub/repos/apt` in the suite-specific `*-pgdg/main` index; the package was installed and its control/SQL/library payload inspected on amd64 in both suites. The Trixie PG18 arm64 package was also installed under QEMU; package versions matched amd64, with `Architecture: arm64` for this native package (and `all` for architecture-independent packages).

| Debian suite | PGDG package | Installed candidate | Architecture |
| --- | --- | --- | --- |
| Bookworm | `postgresql-18-pg-wait-sampling` | `1.1.11-1.pgdg12+1` | amd64 |
| Trixie | `postgresql-18-pg-wait-sampling` | `1.1.11-1.pgdg13+1` | amd64 |

The selected catalog version is `1.1`. The package copyright declares `PostgreSQL`. The Dockerfile copies the package copyright notice into `/licenses/postgresql-18-pg-wait-sampling/`, and ships only the server library/SQL files required by CNPG. C shared library depends on libc6 from the CNPG base image; no extra runtime package. There is no project-built or static bundled dependency. PGDG package updates are tracked by the `renovate:` annotations in `metadata.hcl`; rebuilds use the matching PG18 minimal base image.

## Functional and build verification

- Disposable PG18.6/Trixie server with the exact PGDG package and `pg_wait_sampling` preloaded: the fixture observed wait-event samples after inducing a sleep.
- Dockerfile builds using CNPG PG18 minimal Bookworm and Trixie bases: pass on amd64. Final images contain the package copyright and generated `runtime-packages.tsv`; scratch contents were inspected.

## Integrated validation

`task e2e:test:full TARGET=pg-wait-sampling DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
