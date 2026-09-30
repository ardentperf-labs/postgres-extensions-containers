# Package provenance and runtime evidence

Verified 2026-09-29 in disposable CloudNativePG PG18 minimal containers. `apt search` and `apt-cache policy` confirmed the package candidate from `https://apt.postgresql.org/pub/repos/apt` (`bookworm-pgdg/main` and `trixie-pgdg/main`); exact versions below were installed and `dpkg -L`, package controls, SQL files, dependencies and copyright were inspected on amd64. Trixie arm64 package installation also passed; a separate Bookworm arm64 package probe was not run. Integrated image-build coverage is recorded below.

| Debian suite | PGDG package | Installed version | Architecture evidence |
| --- | --- | --- | --- |
| Bookworm | `postgresql-18-powa` | `5.3.0-1.pgdg12+2` | amd64 installed |
| Trixie | `postgresql-18-powa` | `5.3.0-1.pgdg13+2` | amd64 and arm64 installed |

The main component license is `PostgreSQL`. Both exact PGDG binary packages contain `/usr/lib/postgresql/18/lib/powa.so`, `/usr/lib/postgresql/18/lib/bitcode/powa/powa.bc`, `/usr/lib/postgresql/18/lib/bitcode/powa.index.bc`, the `powa.control` file, and the SQL install/upgrade scripts. The image copies the server module, only PoWA's own bitcode, the control/SQL payload, and the full PGDG package copyright to `/licenses/postgresql-18-powa/`. Inspection of each module with `ldd` found only libc and the ELF loader, supplied by the CNPG base image. The generated `/licenses/runtime-packages.tsv` records the installed extension, PostgreSQL, and libc package versions and architectures. Package upgrades are tracked from the exact PGDG binary package using the Renovate annotations in `metadata.hcl`; the matching PGDG source package is available from the same suite-specific repository. There is no statically linked third-party component.

## Dependencies and payload

Requires the CNPG base-image `pg_stat_statements` and `btree_gist` extensions. Preloads `pg_stat_statements` and the packaged `powa.so` background-worker module; an external PoWA collector/archivist and web UI are optional client components.

## Functional and build verification

- Disposable PG18.6/Trixie server with PGDG PoWA, `pg_stat_statements` and `btree_gist`: exercised statements, called `powa_take_snapshot()`, and asserted statement-history rows were persisted.
- Exact Bookworm/Trixie amd64 package archives were inspected after this preload failure was found: both include the shared library and own bitcode listed above; `ldd` succeeds with only the base-provided libc and loader. The Dockerfile now validates the module and stages those files.
- Final images built on amd64 and arm64 and passed both-suite CNPG Chainsaw retests on amd64. Arm64 runtime testing was unavailable.

## Integrated validation

`task e2e:test:full TARGET=powa DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
