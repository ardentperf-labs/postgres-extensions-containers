# Package and build evidence for DocumentDB

## PGDG provenance and SQL mapping

The PG18 package is available from PGDG on Trixie only. Disposable PG18/Trixie/amd64 CNPG minimal-image inspection confirmed the PGDG candidate, package control/dependencies, installed files and SQL controls; Bookworm has no PG18 package in the checked PGDG indexes. The 2026-09-29 PGDG audit indexes show both amd64 and arm64 Trixie packages.

| Debian suite | PG18 package | SQL extensions staged | Architecture evidence |
|---|---|---|---|
| trixie | `postgresql-18-documentdb` `1.0~RC1-1.pgdg13+1` | `documentdb` `1.0-0`; `documentdb_core` `1.0-0`; `documentdb_extended_rum` `1.0-0` | PGDG amd64 and arm64 indexes |

The PGDG package also contains `documentdb_distributed` controls, SQL and a library. Those artifacts are deliberately omitted from the image because the component requires Citus. A fresh `apt-get update` and `apt-cache policy/search postgresql-18-citus` in the PG18/Trixie CNPG minimal image returned no PGDG package candidate or search result, and this catalog has no compatible Citus image. A future compatible PG18/Trixie Citus dependency image is the concrete path to supporting the distributed component. The exact PGDG `documentdb` source archive remains bundled and contains the omitted component's AGPL source.

Database setup creates the required dependencies (including `documentdb_core`) before `documentdb`; the optional `documentdb_extended_rum` SQL extension is created after the main extension because its install script uses the main DocumentDB API. The image preloads the main, core, and extended-RUM libraries plus `pg_cron`. The README and functional job cover this install order, BSON insert/query/update behavior, and creation of a DocumentDB RUM index.

## Runtime closure and licensing

The scratch payload includes only `pg_documentdb.so`, `pg_documentdb_core.so`, `pg_documentdb_extended_rum*.so`, their bitcode when present, and the three supported controls and SQL script sets. `documentdb_distributed` artifacts are excluded. The package's exact source archive is staged under `/source`; complete package copyright and Debian common license texts are under `/licenses`. The selected package is AGPL-3.0-or-later, Expat/MIT, Apache-2.0 and PostgreSQL licensed. Runtime libraries matched the CNPG PG18/Trixie base in the package probe; `/licenses/base-linkages.txt` records exact package versions and architectures, while `/licenses/runtime-packages.txt` records the extension package. The update path is the Renovate-tracked PGDG package version and base image; each rebuild regenerates these manifests and source artifacts.

## CNPG local libpq authentication

The PGDG `v1.0-RC1` source defines the SUSET GUC `documentdb.localhost_connection_string`, defaulting to `host=localhost`; the extension appends its current port, authenticated SQL user and database to this value when opening local libpq connections. The upstream PostgreSQL configuration sample documents setting it to `host=<socket-dir> port=<port>` for the target instance. The inspected CNPG Trixie server exposes its Unix socket at `/controller/run/.s.PGSQL.5432` and has a local peer-authentication rule, while TCP localhost uses SCRAM. Metadata now sets `host=/controller/run`, selecting the existing local peer-auth path without adding or broadening any HBA rule. The functional fixture asserts this setting before exercising the BSON API and confirms its role context (`session_user=postgres`, `current_user=app`). The `SET ROLE` arrangement is deliberate: PostgreSQL keeps the authenticated session user at `postgres`, which is what DocumentDB's internal libpq self-connection uses. This example does not claim that a direct app-authenticated SQL session works with CNPG's default peer identity mapping. The final CNPG functional run passed with this session/effective-role arrangement; its exact source hashes and image digests are recorded below.

## Validation status

- PGDG package installation, origin, control files, SQL files, version and direct dependencies: inspected on disposable PG18/Trixie/amd64 CNPG minimal image. PG18 Bookworm absence and Trixie amd64/arm64 availability were checked against APT indexes.
- A pre-filter scratch image was built and its payload mounted into a fresh minimal PG18/Trixie server. With `pg_cron`, pgvector, PostGIS and RUM dependencies present, `documentdb`, BSON collection creation/insert/query/update, `documentdb_extended_rum`, and BSON RUM index creation succeeded. The insert/query/update checks ran with `current_user=app` under a PostgreSQL administrator-authenticated session.
- The original live CNPG functional failure was traced to libpq using `host=localhost` and encountering TCP SCRAM without a password. The metadata and fixture now select and assert CNPG's local peer-authenticated socket; the post-fix CNPG suite passed.
- The final filtered scratch image passed both architecture builds and the CNPG mounted-payload tests.
- Chainsaw YAML parsing, the generic and functional CNPG suites, and the actual README deployment passed. Repository-wide check evidence is linked below.

## Integrated validation

`task e2e:test:full TARGET=documentdb DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
