# Package and runtime evidence: PL/JS

Checked 2026-09-29 against PGDG Bookworm and Trixie indexes for PG18. Upstream: https://github.com/pljs/PLJS. Package `postgresql-18-pljs` comes from PGDG `bookworm-pgdg/main` (`1.0.5-1.pgdg12+1`) and `trixie-pgdg/main` (`1.0.5-1.pgdg13+1`); source package is `pljs`. The installed package provides `pljs.control`, SQL catalog files and `pljs.so`. Both architectures are listed in the live package indexes/audit; direct runtime test here used amd64.

PLJS declares custom project terms recorded in Debian copyright and uses vendored QuickJS under MIT. QuickJS source is carried in PGDG's `debian/patches/quickjs.patch`; the source package, patch and full Debian copyright are included under `/source/` and `/licenses/`. The fuzz-only Apache-2.0 material referenced by the vendored component is covered by the complete `/licenses/Apache-2.0` text. QuickJS is statically linked, so `pljs.so` has no additional runtime library beyond the CNPG base. The image-generated `/licenses/runtime-packages.tsv` records exact extension, server and dynamic-library owner package/source versions.

## Functional fixture results

The exact `test/sql.yaml` SQL was extracted with `yaml.safe_load`, after creating `pljs` in a fresh database, and run with `psql -X -h 127.0.0.1 -p 55432 -v ON_ERROR_STOP=1 -f /tmp/pljs-functional.sql` against the disposable PG18 package-install servers. It calls a JavaScript function with a named SQL argument and checks `js_double(21) = 42`.

- Fixture SHA-256: `f5821cd4d8ac543563da275348c25a6fc0e7247cbb4c01417a8510b4c4de314a`.
- Bookworm amd64, PG18.6: **PASS** (`CREATE FUNCTION`, `DO`).
- Trixie amd64, PG18.6: **PASS** (`CREATE FUNCTION`, `DO`).

These package-install fixture results are separate from the image-build and CNPG operator results recorded below.

## Integrated validation

`task e2e:test:full TARGET=pljs DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
