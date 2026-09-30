# Package provenance and runtime evidence

Verified 2026-09-29 in disposable CloudNativePG PG18 minimal containers. `apt search` and `apt-cache policy` confirmed the package candidate from `https://apt.postgresql.org/pub/repos/apt` (`bookworm-pgdg/main` and `trixie-pgdg/main`); exact versions below were installed and `dpkg -L`, package controls, SQL files, dependencies and copyright were inspected on amd64. The earlier agent reported a Trixie arm64 package probe; final matrix build results are recorded below. Revalidated amd64 installs, file lists, control files, copyright and ldd are preserved under `evidence/<suite>/`.

| Debian suite | PGDG package | Installed version | Architecture evidence |
| --- | --- | --- | --- |
| Bookworm | `postgresql-18-pglogical` | `2.4.8-1.pgdg12+1` | amd64 installed |
| Trixie | `postgresql-18-pglogical` | `2.4.8-1.pgdg13+1` | amd64 and arm64 installed |

The main component license is `PostgreSQL`. The image carries the full PGDG package copyright in `/licenses/postgresql-18-pglogical/`; any separately bundled runtime library and its copyright are named in the README. The generated `/licenses/runtime-packages.tsv` records the installed PGDG package and any copied system-library package versions. Package upgrades are tracked from the exact PGDG binary package using the Renovate annotations in `metadata.hcl`; the matching PGDG source package is available from the same suite-specific repository. The source linkage review and exact source descriptor are under `evidence/source/`.

## Dependencies and payload

Server library depends on base-image libc/libpq. No additional runtime library is bundled. The plugin is enabled in PostgreSQL 18 `output_plugin_libraries`.

## Functional verification

- Disposable PG18/Trixie package/control/payload probe: passed. Initial copy and INSERT/UPDATE/DELETE/TRUNCATE replication passed with schema synchronization disabled.
- Bookworm amd64 functional fixture: passed against the exact installed PGDG package.
- `task checks TARGET=pglogical`: passed.

## Integrated validation

`task e2e:test:full TARGET=pglogical DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
