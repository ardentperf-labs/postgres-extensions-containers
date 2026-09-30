# Package and runtime evidence: PL/Lua

Checked 2026-09-29 against PGDG Bookworm and Trixie indexes for PG18. Upstream: https://github.com/pllua/pllua. PGDG package is `postgresql-18-pllua`, source `postgresql-pllua`; versions are `1:2.0.12-7.pgdg12+1` (`bookworm-pgdg/main`) and `1:2.0.12-7.pgdg13+1` (`trixie-pgdg/main`). Debian Lua runtime is `liblua5.3-0` 5.3.6-2 on Bookworm and 5.3.6-2+b4 on Trixie, from Debian source `lua5.3` version 5.3.6-2. CNPG provides the PG18 server and base system-library closure. `dpkg -L`, control files, scripts and `ldd` were inspected in disposable CNPG PG18 containers. Both amd64 and arm64 are listed in the package indexes/audit; runtime tests here used amd64.

The final image copies PL/Lua modules/control/SQL files and `liblua5.3.so.0` into `/lib`. It includes the exact PGDG and Lua Debian source artifacts obtained using package-reported source package/source version, Debian copyright files, and a generated `/licenses/runtime-packages.tsv` inventory for extension, server, Lua and every package owning an `ldd` library. PL/Lua and Lua are MIT/Expat; full copyright/license terms accompany their source packages. The manifest records the additional `hstore_pllua` module shipped by PGDG; that optional transform needs CNPG's base `hstore` extension.

## Functional fixture results

The exact `test/sql.yaml` SQL was extracted with `yaml.safe_load`, after creating `pllua` in a fresh database, and executed using `psql -X -h 127.0.0.1 -p 55432 -v ON_ERROR_STOP=1 -f /tmp/pllua-functional.sql` inside each disposable package-install container. The fixture verifies named-argument arithmetic, trusted interpreter hiding `os.execute`, and untrusted interpreter exposing the function without invoking it.

- Fixture SHA-256: `d5ca76e65316615adcbaf2789589356a949cf2a1bd32e30c4d4e570c35cfb0d3`.
- Bookworm amd64, PG18.6: **PASS** (`CREATE EXTENSION plluau`, three `CREATE FUNCTION`, `DO`).
- Trixie amd64, PG18.6: **PASS** (same assertions).

These package-install fixture results are separate from the image-build and CNPG operator results recorded below.

## Integrated validation

`task e2e:test:full TARGET=pllua DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
