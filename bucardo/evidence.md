# Package provenance and runtime evidence

Verified 2026-09-29 in disposable CloudNativePG PG18 minimal containers. `apt search` and `apt-cache policy` confirmed the package candidate from `https://apt.postgresql.org/pub/repos/apt` (`bookworm-pgdg/main` and `trixie-pgdg/main`); exact versions below were installed and `dpkg -L`, package controls, SQL files, dependencies and copyright were inspected on amd64. Trixie arm64 package installation also passed; a separate Bookworm arm64 package probe was not run. Integrated image-build coverage is recorded below.

| Debian suite | PGDG package | Installed version | Architecture evidence |
| --- | --- | --- | --- |
| Bookworm | `bucardo` | `5.6.0-6.pgdg12+1` | amd64 installed |
| Trixie | `bucardo` | `5.6.0-6.pgdg13+1` | amd64 and arm64 installed |

The main component license is `BSD-2-Clause`. The image carries the full PGDG package copyright in `/licenses/bucardo/`; the image includes only the accounted server payload and base-image runtime dependencies. The generated `/licenses/runtime-packages.tsv` records the installed PGDG package and any copied system-library package versions. Package upgrades are tracked from the exact PGDG binary package using the Renovate annotations in `metadata.hcl`; the matching PGDG source package is available from the same suite-specific repository. There is no statically linked third-party component.

## Dependencies and payload

`plperl` runtime image; upstream SQL uses Perl DBI and DBD::Pg. The external daemon is not included in this server image.

## Functional and build verification

- Installed PGDG Bucardo `5.6.0-6.pgdg13+1` and PL/Perl 18 in a disposable PG18.6/Trixie container. Loaded the packaged 101,740-byte SQL source, started Bucardo as an external `postgres` OS process, and verified initial copy, INSERT, UPDATE, DELETE, TRUNCATE, and INSERT-after-TRUNCATE against target row values.
- Dockerfile builds using CNPG PG18 minimal Bookworm and Trixie bases: pass on amd64. The Trixie image’s `/share/extension/bucardo.schema` SHA-256 matched the copied PGDG schema source. The Chainsaw Job mounts the Bucardo image itself read-only, checks that hash, and executes the mounted file.

## Integrated validation

`task e2e:test:full TARGET=bucardo DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
