# Package and build evidence for RDKit

## PGDG package verification

The PG18 package is available from PGDG on Trixie only in the audited matrix. A disposable PG18/Trixie/amd64 CNPG minimal container confirmed the PGDG package install, package files, control/SQL payload and functional SQL. The 2026-09-29 indexes show Trixie packages for amd64 and arm64; Bookworm has no PG18 package.

| Debian suite | PG18 package version | SQL catalog version | Architecture evidence |
|---|---|---|---|
| trixie | `postgresql-18-rdkit` `202503.1-5.pgdg13+1` | `rdkit` `4.7.0` | PGDG amd64 and arm64 indexes |

The cartridge is BSD-3-Clause licensed. The final image build records exact runtime package versions and architectures, package notices and any required source archives in `/licenses` and `/source`; the PG18/Trixie base-image linkage inventory is recorded separately. Renovate tracks the PGDG package, and a rebuild refreshes the linked runtime closure and its notices.

## Validation status

- PGDG install and payload/control inspection: completed on disposable PG18/Trixie/amd64 CNPG minimal image. Bookworm absence and Trixie amd64/arm64 availability were checked against PGDG indexes.
- `CREATE EXTENSION rdkit` and the exact functional expression from the job succeeded on the installed package: `mol_to_smiles(mol_from_smiles('CCO'))::text = 'CCO' AND size(morganbv_fp(mol_from_smiles('CCO'))) > 0` returned true. The explicit `::text` cast is needed because `mol_to_smiles()` returns `cstring`; `size()` is the supported bit-count function for the returned `bfp`.
- Current scratch Dockerfile built successfully for `linux/amd64` on 2026-09-29 with:

  ```sh
  docker build --platform linux/amd64 --progress plain \
    --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie \
    --build-arg PG_MAJOR=18 --build-arg EXT_VERSION=202503.1-5.pgdg13+1 \
    -f rdkit/Dockerfile -t rdkit-final-check-trixie-amd64:local .
  ```

  The resulting image ID is `sha256:ca5cffda1335ead4a916e261ff109ce464f412add65eb5779f3593bae62e09c3` (243,382,233 bytes). The build's `ldd /usr/lib/postgresql/18/lib/rdkit.so` closure resolved fully. Its shipped `/licenses/runtime-packages.txt` contains these exact copied runtime package versions and architecture:

  ```text
  libboost-iostreams1.83.0 1.83.0-4.2 amd64
  libboost-serialization1.83.0 1.83.0-4.2 amd64
  libbrotli1 1.1.0-2+b7 amd64
  libcairo2 1.18.4-1+b1 amd64
  libcoordgen3 3.0.2-1+b2 amd64
  libexpat1 2.8.3-1~deb13u1 amd64
  libfontconfig1 2.15.0-2.3 amd64
  libfreetype6 2.13.3+dfsg-1+deb13u1 amd64
  libmaeparser1 1.3.1-1+b2 amd64
  libpixman-1-0 0.44.0-3 amd64
  libpng16-16t64 1.6.48-1+deb13u5 amd64
  librdkit1t64 202503.1-5.pgdg13+1 amd64
  libx11-6 2:1.8.12-1 amd64
  libxau6 1:1.0.11-1 amd64
  libxcb-render0 1.17.0-2+b1 amd64
  libxcb-shm0 1.17.0-2+b1 amd64
  libxcb1 1.17.0-2+b1 amd64
  libxdmcp6 1:1.1.5-1 amd64
  libxext6 2:1.3.4-1+b3 amd64
  libxrender1 0.9.12-1 amd64
  postgresql-18-rdkit 202503.1-5.pgdg13+1 amd64
  ```

  `/licenses/base-linkages.txt` separately records the six PG18/Trixie base packages that satisfy the remaining non-glibc `ldd` entries: `libbz2-1.0 1.0.8-6`, `libgcc-s1 14.2.0-19`, `liblzma5 5.8.1-1+deb13u1`, `libstdc++6 14.2.0-19`, `libzstd1 1.5.7+dfsg-1`, and `zlib1g 1:1.3.dfsg+really1.3.1-1+b1` (all amd64). The build carries full runtime package copyright notices and common-license texts. Because copyright files in the copied closure include GPL text, the image also carries exact source archives and source-version entries for `cairo 1.18.4-1`, `freetype 2.13.3+dfsg-1+deb13u1`, `libpng1.6 1.6.48-1+deb13u5`, and `rdkit 202503.1-5.pgdg13+1`. The libpng shared library's copyright identifies its linked library code as libpng-licensed; source is bundled conservatively because the Debian copyright file also covers GPL-licensed contributed/packaging files.
- Fresh mounted-payload check completed on a disposable PG18/Trixie/amd64 CNPG minimal container. I copied the built image's actual `/lib`, `/system`, and `/share/extension` trees into separate read-only mounts at `/extensions/rdkit/{lib,system,share/extension}`. The container ran as CNPG UID 26 with `LD_LIBRARY_PATH=/extensions/rdkit/system`, `dynamic_library_path=/extensions/rdkit/lib:/usr/lib/postgresql/18/lib`, and `extension_control_path=/extensions/rdkit/share:/usr/share/postgresql/18`; PG18 appends `/extension` to each control-path entry. A fresh `initdb`, `createdb app`, and `CREATE EXTENSION rdkit` succeeded. The exact SQL block was extracted from `test/functional-job.yaml` and run with `psql -XqAtv ON_ERROR_STOP=1 -d app -f /tmp/test.sql`; it returned `t`. That SQL's SHA-256 was `dc281235a000d81f51e2d667756991dcf9e14d1b498e8155f4ee7bc0fdc3395c`.
- Full CNPG operator/Chainsaw execution, PGDG root architecture/matrix builds (including arm64), and full repository checks remain in the serialized root queue; this local mounted-payload test does not claim those results.

## Integrated validation

`task e2e:test:full TARGET=rdkit DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
