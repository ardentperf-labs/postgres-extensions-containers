# pg-gvm validation evidence

Verified 2026-09-29. PGDG Trixie supplies `postgresql-18-pg-gvm`
`22.6.17-1.pgdg13+2`; its SQL control version is `22.6`. Fresh disposable
CNPG PG18 minimal Trixie and Bookworm containers ran `apt-get update`,
`apt-cache policy postgresql-18-pg-gvm` and `apt search
'^postgresql-18-pg-gvm$'`. Trixie resolves the package from
`apt.postgresql.org trixie-pgdg/main`; Bookworm has no PG18 package. The Trixie
installation, `dpkg -L`, control, copyright and `ldd` inspection are preserved
under `evidence/trixie/`; fresh origin/search output exists for both suites.

The package was scaffolded with the documented custom-package Dagger workflow.
The final scratch Dockerfile was built on amd64 with:

```sh
docker build -f pg-gvm/Dockerfile --build-arg PG_MAJOR=18 \
  --build-arg EXT_VERSION=22.6.17-1.pgdg13+2 \
  --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie \
  -t extension-batch-pg-gvm:trixie .
```

Initial amd64 build and mounted-payload checks below passed before the additional
GCC source archives were added; the final full workflow rebuilds that expanded
source payload. Exported the scratch payload and mounted it read-only at
`/extensions/pg-gvm` in a fresh matching CNPG minimal image, setting
`LD_LIBRARY_PATH=/extensions/pg-gvm/system` and PostgreSQL's extension/control
search paths. Installed no packages in that runtime container. `CREATE EXTENSION
"pg-gvm"` succeeded. The exact [functional fixture](test/functional.sql) returned
`t` as a nonsuperuser: positive/negative regex, NULL propagation and the expected
UTC recurrence timestamp. This tests the native regex and libical functionality,
not only extension registration.

The source CMake configuration under `evidence/source/` links libical and
libgvm_base dynamically; GLib is a transitive dependency. No additional vendored
library is compiled into the extension. Exact PGDG pg-gvm and gvm-libs source,
Debian libical, GLib and GCC source archives (including packaging/build scripts) are
shipped under `/source`. The installed binaries' source versions are used,
including the libical binNMU-to-source version distinction. GPL/AGPL notices and
full common license texts are included; pg-gvm's Debian copyright contains the
full AGPL text. ICU/PCRE2 permissive notices and the GCC runtime exception are
retained. Runtime/source package manifests are included in the image and recorded
under `evidence/trixie/`; the matching base supplies libc and the ELF loader.

Full CNPG Chainsaw, README deployment and amd64/arm64 Bake results are recorded
separately under `evidence/runtime/` when completed. The standalone amd64 check
does not claim arm64 runtime coverage.

## Integrated validation

`task e2e:test:full TARGET=pg-gvm DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
