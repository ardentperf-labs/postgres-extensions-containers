# set_user: implementation evidence

Inspection date: 2026-09-29; host amd64. Scaffolded with the documented Dagger create command.

Upstream: https://github.com/pgaudit/set_user

| Distribution | PGDG package | Installed version | Catalog version |
|---|---|---|---|
| bookworm | `postgresql-18-set-user` | `4.2.0-1.pgdg12+2` | `4.2.0` |
| trixie | `postgresql-18-set-user` | `4.2.0-1.pgdg13+2` | `4.2.0` |

For each distribution: `docker run -u root ghcr.io/cloudnative-pg/postgresql:18-minimal-<distro>`; `apt-get update`, `apt search`, `apt-cache policy`, `apt-cache show`, `apt-get install --no-install-recommends`, `dpkg -L`, inspect controls and copyright, and `ldd` on shipped shared libraries. Both installations passed. Full APT origin/payload/linkage evidence is alongside this document. Dependencies supplied by the base are not duplicated. Source build/linkage review is recorded under `evidence/source/`.

Package inspection above is separate from the integrated validation below.

## Integrated validation

`task e2e:test:full TARGET=set-user DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
