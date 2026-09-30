# Package and runtime evidence: unit

Checked 2026-09-29 against PGDG's live APT indexes. Upstream homepage: https://github.com/df7cb/postgresql-unit. PG18 package: `postgresql-18-unit`; source package: `postgresql-unit` (Bookworm `7.10-2.pgdg12+1`, Trixie `7.10-2.pgdg13+1`). The historical audit records PG18 availability on both architectures for Bookworm and Trixie.

| Debian suite | PGDG package version | Index source |
|---|---|---|
| Bookworm | `7.10-2.pgdg12+1` | `https://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main` |
| Trixie | `7.10-2.pgdg13+1` | `https://apt.postgresql.org/pub/repos/apt trixie-pgdg/main` |

The PG18 control file is `unit.control` (SQL name `unit`, default version `7`). The package installs its extension control/SQL files under `/usr/share/postgresql/18/extension/` and is copied to `/share/extension/`. The shared object `unit.so` is copied to `/lib/`.

License declared by package copyright: GPL-3.0-or-later.
The Debian copyright file is included at `/licenses/postgresql-18-unit/copyright` with upstream attribution, packaging terms and component notices.
The referenced full common-license text is copied to `/licenses/GPL-3`.
The CNPG base image provides PostgreSQL and any required system runtime libraries; no additional runtime packages are installed in the final scratch image. If present, the package shared object is copied alongside its control/SQL files, and no external extension shared-library package was identified.
Versioned PostgreSQL and libc base-runtime package dependencies, plus the dynamic-library list, are recorded by suite in `dependency-manifest.json`.
The build also writes `/licenses/runtime-packages.tsv` from installed `dpkg-query` metadata for the extension, PostgreSQL server and Debian package owners of each resolved shared library, so the image carries the exact package and source versions actually used.
The multi-stage Docker build enables signed PGDG source indexes and runs `apt-get source --download-only postgresql-unit=7.10-2.pgdg13+1` on Trixie and `postgresql-unit=7.10-2.pgdg12+1` on Bookworm; both were verified. The exact `.dsc`, upstream orig archive and Debian packaging archive are included in the final image under `/source/` (see `dependency-manifest.json`).

The installed package's `unit--7.sql` and six older install/upgrade scripts contain 14 server-side `COPY` references to `/usr/share/postgresql/18/extension/unit_{prefixes,units}.data`. The final CNPG payload mounts these files under `/extensions/unit/share/extension/`, so the Docker build applies `patches/0001-use-cnpg-mounted-data-files.patch` to all seven affected SQL files and verifies no old paths remain and all 14 rewritten paths are present. The patch is version-controlled here and copied beside the exact PGDG source archives in the image at `/source/patches/`; the SQL stays GPL-3.0-or-later and its complete corresponding source plus local change are shipped.

I installed the exact Bookworm `7.10-2.pgdg12+1` and Trixie `7.10-2.pgdg13+1` packages in disposable CNPG PG18 containers and compared all `unit--*.sql` SHA-256 values: the SQL files are byte-identical between suites. The package's v7 default install SQL and historical upgrade scripts were inspected; only the seven files listed in the manifest load `.data` files.


## Commands and results

Package discovery and installation were run in disposable PG18 CNPG containers:

- Trixie amd64: `docker run --rm -i -u root ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie bash -s`, then `apt-get update -qq`, `apt-cache search --names-only '^postgresql-18-unit$'`, `apt-cache policy postgresql-18-unit`, `apt-get install -y --no-install-recommends postgresql-18-unit`, `dpkg-query -W`, `dpkg -L`, and inspection of the installed `.control`, copyright file, and extension `.so` with `ldd` when present. The candidate came from `https://apt.postgresql.org/pub/repos/apt trixie-pgdg/main`.
- Bookworm amd64: same commands in `ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm`; the candidate came from `https://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main`.
- Trixie arm64: `docker run --rm -i --platform linux/arm64 -u root ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie bash -s`, followed by `apt-get update -qq`, `apt-get install -y --no-install-recommends postgresql-18-unit`, `dpkg-query -W`, `dpkg -L`, and control-file inspection. Installed package architecture was arm64 (or `all` for architecture-independent SQL packages).

A disposable PG18/Trixie/amd64 PostgreSQL server installed the package and ran `CREATE EXTENSION unit;` successfully. The functional assertion used by this target's Chainsaw test was run against that server and returned `t`:

```sql
'1 m'::unit = '100 cm'::unit
```

The extension-specific Chainsaw suite provisions a fresh CNPG Cluster and Database, then executes the same assertion using an Alpine/psql Job through the Cluster's CNPG-managed service. The orchestrator's target-specific operator E2E and architecture-matrix build outcomes are not claimed in this package-probe section; the separate local amd64 scratch builds and mounted-payload smoke tests are recorded below.

## Exact Chainsaw fixture rerun (2026-09-29)

Fixture: `test/functional.yaml`, SHA-256 `e3e5e121ad0a1c7fe1fab3db4bea07ef6d44b789f934b34e366be572f30bc31d`. I installed the package from PGDG and created `CREATE EXTENSION unit;` in disposable PG18.6 servers based on `ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm` and `ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie`. I extracted this exact fixture SQL and invoked `docker exec -i simple-ext-fixture-<distro> psql -h 127.0.0.1 -p 55432 -U postgres -d postgres -X -v ON_ERROR_STOP=1 -Atq -c "$TEST_SQL"` for the scalar query (for RUM, passed the exact embedded SQL block from this file to the same `psql` command). Results: Bookworm **PASS** (`t`); Trixie **PASS** (`t`). The fixture's SQL and hash are shown here so the reported result stays tied to the tested file revision:

```sql
SELECT '1 m'::unit = '100 cm'::unit
```

## Patched image build and mounted-payload validation (2026-09-29)

I built the current `unit/Dockerfile` directly with Docker on linux/amd64 for both supported suites; both builds passed, including the patch dry-run/apply guard, source download, runtime package inventory, and final scratch-image copy:

```sh
docker build --platform linux/amd64 --progress plain \
  --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm \
  --build-arg PG_MAJOR=18 --build-arg EXT_VERSION=7.10-2.pgdg12+1 \
  -f unit/Dockerfile -t unit-mount-fix-bookworm:local .
docker build --platform linux/amd64 --progress plain \
  --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie \
  --build-arg PG_MAJOR=18 --build-arg EXT_VERSION=7.10-2.pgdg13+1 \
  -f unit/Dockerfile -t unit-mount-fix-trixie:local .
```

For each suite I made a disposable test layer from the fresh CNPG minimal base and copied the scratch image's `/lib` and `/share/extension` into `/extensions/unit/lib` and `/extensions/unit/share/extension`, matching the extension mount layout. I initialized PostgreSQL 18 in that container and started it with `extension_control_path=/usr/share/postgresql/18:/extensions/unit/share` and `dynamic_library_path=/usr/lib/postgresql/18/lib:/extensions/unit/lib`; `CREATE EXTENSION unit; SELECT '1 m'::unit = '100 cm'::unit;` returned **`t`** on Bookworm and Trixie. Both mounted `.data` files were readable by the PostgreSQL user. This validates the patched data-file paths against the mounted payload; it is a disposable mounted-layout smoke test, not the orchestrator's CNPG operator E2E.

Patch SHA-256: `d2046a33f1031d20c74b309e3f7bb771bd58a4656736e1abda5c41e31d3455d5`. The resulting scratch image IDs were Bookworm `sha256:00c2631ff57c8d4b5d0d4159fd0c5ad749cb9aa8a02c03383e78123031dd1bbe` and Trixie `sha256:86a2b633f12cd567c0b3643ab4b411058d279e4e7b3489a5aa089afa75497869`. The build-specific `/licenses/runtime-packages.tsv` was generated in each image; the image build and operator-suite results will be recorded separately by the orchestrator.

## Integrated validation

`task e2e:test:full TARGET=unit DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
