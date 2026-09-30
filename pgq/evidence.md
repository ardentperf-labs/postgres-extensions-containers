# Package provenance and runtime evidence

Verified 2026-09-29 in disposable CloudNativePG PG18 minimal containers. `apt search` and `apt-cache policy` confirmed the package candidate from `https://apt.postgresql.org/pub/repos/apt` (`bookworm-pgdg/main` and `trixie-pgdg/main`); exact versions below were installed and `dpkg -L`, package controls, SQL files, dependencies and copyright were inspected on amd64. Trixie arm64 package installation also passed; a separate Bookworm arm64 package probe was not run. Integrated image-build coverage is recorded below.

| Debian suite | PGDG package | Installed version | Architecture evidence |
| --- | --- | --- | --- |
| Bookworm | `postgresql-18-pgq3` | `3.5.1-2.pgdg12+1` | amd64 installed |
| Trixie | `postgresql-18-pgq3` | `3.5.1-2.pgdg13+1` | amd64 and arm64 installed |

The main component license is `ISC`. The image carries the full PGDG package copyright in `/licenses/postgresql-18-pgq3/`; the image includes only the accounted server payload and base-image runtime dependencies. The generated `/licenses/runtime-packages.tsv` records the installed PGDG package and any copied system-library package versions. Package upgrades are tracked from the exact PGDG binary package using the Renovate annotations in `metadata.hcl`; the matching PGDG source package is available from the same suite-specific repository. There is no statically linked third-party component.

## Dependencies and payload

Server C helpers use libc/libpq from the base image. The PGQ tick/maintenance daemon is not bundled; run PGDG `pgqd` separately and connect through a CNPG `-rw` service.

## Functional and build verification

- Disposable PG18.6/Trixie server with the exact PGDG package: created a queue, inserted an event, and asserted a positive event ID and visible queue metadata.
- Dockerfile builds using CNPG PG18 minimal Bookworm and Trixie bases: pass on amd64. The final image carries the server C helper and SQL only; the separately operated `pgqd` daemon is not copied. Runtime package manifest and copyright payload were inspected.

## Integrated validation

`task e2e:test:full TARGET=pgq DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
