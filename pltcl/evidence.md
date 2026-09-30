# Package and runtime evidence: PL/Tcl

Checked 2026-09-29 against PGDG Bookworm and Trixie indexes for PG18. Upstream is PostgreSQL's PL/Tcl implementation. PGDG `postgresql-pltcl-18` versions are `18.6-1.pgdg12+2` (`bookworm-pgdg/main`) and `18.6-1.pgdg13+2` (`trixie-pgdg/main`), source `postgresql-18`. Debian `libtcl8.6` is `8.6.13+dfsg-2` on Bookworm and `8.6.16+dfsg-1` on Trixie, source `tcl8.6`. `dpkg -L`, trusted/untrusted control and SQL files, package copyright and `ldd` closure were inspected in disposable PG18 CNPG containers. Both architectures are listed in the package indexes/audit; runtime tests here used amd64.

The final image includes `pltcl.so`, both `pltcl`/`pltclu` catalog definitions and SQL, Tcl 8.6 runtime library and script library, with `TCL_LIBRARY` pointing inside the mounted image. Exact PGDG PostgreSQL and Debian Tcl source artifacts, package copyright files, full referenced common license texts, and `/licenses/runtime-packages.tsv` (extension, server, Tcl, and all dynamic library owners with source versions) are included. The PostgreSQL and Tcl source packages preserve their respective PostgreSQL and TCL license terms; Tcl is dynamically linked and redistributed with its matching source and notices.

## Functional fixture results

The exact `test/sql.yaml` SQL was extracted with `yaml.safe_load`, after creating `pltcl` in a fresh database, and executed using `psql -X -h 127.0.0.1 -p 55432 -v ON_ERROR_STOP=1 -f /tmp/pltcl-functional.sql` inside each disposable package-install container. It checks arithmetic and that `exec` is absent from trusted PL/Tcl but present in untrusted PL/Tcl; it does not execute a shell command.

- Fixture SHA-256: `ee4502af9e3528e44f2740506085e980d28ecfcad41d499b8efe7d2138012c39`.
- Bookworm amd64, PG18.6: **PASS** (`CREATE EXTENSION pltclu`, three `CREATE FUNCTION`, `DO`).
- Trixie amd64, PG18.6: **PASS** (same assertions).

These package-install fixture results are separate from the image-build and CNPG operator results recorded below.

## Integrated validation

`task e2e:test:full TARGET=pltcl DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
