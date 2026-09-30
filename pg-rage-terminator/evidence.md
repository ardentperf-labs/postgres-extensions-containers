# Package provenance and runtime evidence

Verified 2026-09-29 in disposable CloudNativePG PG18 minimal containers. `apt search` and `apt-cache policy` confirmed the package candidate from `https://apt.postgresql.org/pub/repos/apt` (`bookworm-pgdg/main` and `trixie-pgdg/main`); exact versions below were installed and `dpkg -L`, package controls, SQL files, dependencies and copyright were inspected on amd64. Trixie arm64 package installation also passed; a separate Bookworm arm64 package probe was not run. Integrated image-build coverage is recorded below.

| Debian suite | PGDG package | Installed version | Architecture evidence |
| --- | --- | --- | --- |
| Bookworm | `pg-rage-terminator-18` | `0.1.7-12.pgdg12+1` | amd64 installed |
| Trixie | `pg-rage-terminator-18` | `0.1.7-12.pgdg13+1` | amd64 and arm64 installed |

The main component license is `PostgreSQL`. The image carries the full PGDG package copyright in `/licenses/pg-rage-terminator-18/`; the image includes only the accounted server payload and base-image runtime dependencies. The generated `/licenses/runtime-packages.tsv` records the installed PGDG package and any copied system-library package versions. Package upgrades are tracked from the exact PGDG binary package using the Renovate annotations in `metadata.hcl`; the matching PGDG source package is available from the same suite-specific repository. There is no statically linked third-party component.

## Dependencies and payload

C module depends on libc from the CNPG base image. No additional library is bundled. Upstream component source is PGDG `pg-rage-terminator`.

## Functional and build verification

- Disposable PG18.6/Trixie server with the exact PGDG module preloaded and `chance=100`, `interval=1`: a sole TCP fixture ran `SELECT pg_sleep(60)`. The worker logged `Rage terminated connection`, and the client received `FATAL: terminating connection due to administrator command` (psql exit 2). The ChainSaw fixture uses the same isolated setup and treats only this expected message as success; its test cluster is ephemeral and contains no other application TCP clients.
- The user-facing README keeps the normal setting at `chance=0`; the destructive setting is limited to the disposable functional-test Cluster.
- Dockerfile builds using CNPG PG18 minimal Bookworm and Trixie bases: pass on amd64. Final module, package copyright, and generated `runtime-packages.tsv` were inspected.

## Integrated validation

`task e2e:test:full TARGET=pg-rage-terminator DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
