# Package and build evidence for pgpcre

## PGDG package verification

The exact selected package was installed into disposable CloudNativePG PG18 minimal containers on both advertised Debian suites (amd64). `apt-cache policy` showed the candidate in `apt.postgresql.org` PGDG for each suite; `dpkg-query`, package control fields and dependencies, `dpkg -L` payload, extension control/SQL files, and shared-object dependencies were inspected. The 2026-09-29 PGDG audit indexes show package availability on both amd64 and arm64 for each advertised combination.

| Debian suite | PG18 package version | Package origin | Architecture evidence |
|---|---|---|---|
| bookworm | `0.20190509-9.pgdg12+1` | `apt.postgresql.org` (PGDG) | PG18 package in both amd64 and arm64 indexes |
| trixie | `0.20190509-9.pgdg13+1` | `apt.postgresql.org` (PGDG) | PG18 package in both amd64 and arm64 indexes |

Package pattern: `postgresql-{major}-pgpcre`. SQL extension: `pgpcre` at catalog version `1`. Package copyright identifies the extension license as `PostgreSQL`; the Debian copyright text is bundled in `/licenses`.

## Runtime payload and update path

The image installs the version-pinned PGDG package and stages only this extension's shared object, extension control/SQL files, and available LLVM bitcode. At build time, `ldd` resolves non-core dynamic dependencies for the selected suite and architecture. Those libraries are copied to `/system`; their owning Debian package names, exact versions, and architecture are written to `/licenses/runtime-packages.txt`, and their copyright files plus Debian common license texts are copied under `/licenses`. The CNPG base image supplies libc and the ELF loader. For linked runtime packages whose actual library license is GPL/LGPL, the corresponding exact Debian source package is downloaded from the signed `deb-src` archive and staged under `/source`; `/licenses/source-packages.txt` records each source package and version. The source downloader fails closed on an unreviewed copyleft runtime package. Renovate tracks the suite-specific PGDG package; rebuilding refreshes the runtime closure, its version inventory, and required source artifacts.

The PGDG package links to PCRE2 10.42 on Bookworm and 10.46 on Trixie. The build stages the resolved runtime library and its Debian copyright notice. The selected PCRE2 runtime has a permissive license, so no copyleft source archive is required.

## Validation status

- PGDG origin, exact versions, control/SQL payload, direct dependencies, and package installation/payload inspection: completed on disposable Bookworm/amd64 and Trixie/amd64 CNPG PG18 containers.
- Trixie/amd64 and Bookworm/amd64 builder staging commands: executed; staged ELF, control/SQL payload, runtime package/version inventory, copyright files, source package inventory, and source archives inspected.
- Bookworm/Trixie PG18 package availability on amd64 and arm64: confirmed against PGDG indexes; arm64 payload/build not run yet.
- Advertised matrix: PG18 on bookworm, trixie.
- `CREATE EXTENSION pgpcre` and whole-match extraction returned the expected result on the installed Bookworm/amd64 and Trixie/amd64 PG18 packages; the same SQL behavior is covered by the job.
- All target test YAML documents parse successfully. Final repository checks are recorded in the batch evidence.

## Integrated validation

`task e2e:test:full TARGET=pgpcre DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
