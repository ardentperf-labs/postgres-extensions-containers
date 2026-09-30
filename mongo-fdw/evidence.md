# Package and build evidence for mongo_fdw

## PGDG package verification

PGDG publishes PostgreSQL 18 packages on Trixie only in the audited matrix. A disposable PG18/Trixie/amd64 CNPG minimal container confirmed the PGDG origin, exact package version, control file, SQL payload, direct dependencies and installed file list. Bookworm has no PG18 package; the 2026-09-29 PGDG indexes show Trixie packages for amd64 and arm64.

| Debian suite | PG18 package version | SQL catalog version | Architecture evidence |
|---|---|---|---|
| trixie | `postgresql-18-mongo-fdw` `5.5.3-1.pgdg13+1` | `mongo_fdw` `1.1` | PGDG amd64 and arm64 indexes |

The SQL catalog version is `1.1`; `mongo_fdw_version()` returns the integer driver/API version `50503`, not the catalog version. MongoDB remains a separate outbound service.

## Runtime closure, source and update path

The Trixie/amd64 package closure includes `libbson-1.0-0t64` 1.30.4-1+deb13u3, `libjson-c5` 0.18+ds-1, `libmongoc-1.0-0t64` 1.30.4-1+deb13u3, `libmongocrypt0` 1.13.2-1+deb13u1, `libsnappy1v5` 1.2.2-1, `libutf8proc3` 2.9.0-1+b2, and `postgresql-18-mongo-fdw` 5.5.3-1.pgdg13+1 (all amd64). Exact base-image linkage versions are in `/licenses/base-linkages.txt`. The exact `mongo-fdw` LGPL-3.0 source and `mongo-c-driver` Apache-2.0 source artifacts are bundled under `/source`, along with the local driver patch. Package copyright and common license texts are under `/licenses`.

The installed Trixie `mongo-c-driver` 1.30.4-1+deb13u3 source patch for CVE-2026-81524 reverses the `db` and `ns` arguments when `mongoc_collection_aggregate()` calls `_mongoc_aggregate()`. A live query on the unmodified library returned no rows; a direct C-driver probe reported `database name "warehouse.items" invalid: contains "."`. The bundled compatibility patch swaps those arguments while preserving the Debian validation change. The build fails closed on unreviewed driver source versions. `/licenses/mongoc-build.txt` records the source and patch; `/source/mongoc-aggregate-db-order.patch` provides the exact change.

The image metadata records PostgreSQL, LGPL-3.0-only and Apache-2.0 licensing. Rebuild through the Renovate-tracked PGDG package after package or base-image updates; the build regenerates the patched driver, runtime package, linkage, notice and source manifests. Review or remove the compatibility patch when Debian updates `mongo-c-driver`.

## Validation status

- PGDG installation and payload inspection: completed on disposable PG18/Trixie/amd64; Trixie amd64/arm64 availability and Bookworm's PG18 gap checked against PGDG indexes.
- Before the libmongoc correction, the initial Trixie/amd64 scratch payload had a clean `ldd` closure, `CREATE EXTENSION mongo_fdw` succeeded, and `mongo_fdw_version()` returned `50503`; its live query exposed the Debian driver defect below.
- The exact Debian source and patch rebuild path was run independently in a disposable Trixie container with `dpkg-buildpackage`; it produced the architecture-specific `libmongoc-1.0-0t64` binary package and patched shared library.
- A disposable PG18/Trixie install of the same PGDG package reproduced the zero-row failure with unmodified libmongoc against MongoDB 7.0.16. After rebuilding only libmongoc from the exact Debian source with the patch, `SELECT _id, item, qty FROM mongo_items` returned the ObjectId row, `_id::text` returned its hex string, and the exact strict filter returned `t`.
- A fresh minimal PG18/Trixie container with the patched libmongoc mounted into the scratch payload also returned the seeded ObjectId row and strict assertion against the pinned MongoDB 8.0.13 fixture. The fixture now seeds `_id: ObjectId("65a123456789abcdef012345")`, matching the upstream FDW's `_id name` mapping requirement.
- The final Dockerfile passed amd64 and arm64 builds, including the patched driver rebuild. Both CNPG Chainsaw suites, the actual README deployment and final repository checks passed; detailed records are linked below. The fixture waits for readiness and preserves failure diagnostics.

## Integrated validation

`task e2e:test:full TARGET=mongo-fdw DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
