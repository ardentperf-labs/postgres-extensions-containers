# PL/Python 3 implementation evidence

Inspected 2026-09-29 using disposable CNPG PostgreSQL 18 minimal containers.

| Suite | PGDG package | SQL versions |
|---|---|---|
| Trixie | postgresql-plpython3-18 18.6-1.pgdg13+2 | all four extensions 1.0 |
| Bookworm | postgresql-plpython3-18 18.6-1.pgdg12+2 | all four extensions 1.0 |

APT policy/search, actual package installs, file/control and ldd inspection passed in both suites on
amd64. The image was scaffolded with the documented Dagger command; the generated
custom package-name mapping was corrected to `postgresql-plpython3-18`.

Direct scratch builds passed for both suites:
`docker build -f plpython3/Dockerfile --build-arg PG_MAJOR=18
--build-arg EXT_VERSION=<suite version> --build-arg BASE=<matching CNPG minimal image>`.
Exported each image's payload and mounted it read-only at `/extensions/plpython3`
in a fresh matching CNPG minimal container. Set the README's `PYTHONHOME` and
library paths, initialized PostgreSQL, and ran `test/functional.sql` after
`CREATE EXTENSION plpython3u`. Both suites passed all three transforms, SPI,
gzip round-trip, SHA256, SSL-module loading and in-memory SQLite behavior.
No runtime packages were installed in these mounted-image tests.

Per-suite manifests record the actual staged binary/source versions and native
closure. The images include exact corresponding source archives and Debian
packaging. Python core modules and bundled sources follow the Python source
version; separately linked libraries are individually versioned.

Standalone loading above is separate from the integrated validation below.

## Integrated validation

`task e2e:test:full TARGET=plpython3 DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
