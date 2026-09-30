# Package and runtime evidence: asn1oid

Checked 2026-09-29 against PGDG's live APT indexes. Upstream homepage: https://github.com/df7cb/pgsql-asn1oid. PG18 package: `postgresql-18-asn1oid`; source package: `pgsql-asn1oid` (Bookworm `1.6-3.pgdg12+1`, Trixie `1.6-3.pgdg13+1`). The historical audit records PG18 availability on both architectures for Bookworm and Trixie.

| Debian suite | PGDG package version | Index source |
|---|---|---|
| Bookworm | `1.6-3.pgdg12+1` | `https://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main` |
| Trixie | `1.6-3.pgdg13+1` | `https://apt.postgresql.org/pub/repos/apt trixie-pgdg/main` |

The PG18 control file is `asn1oid.control` (SQL name `asn1oid`, default version `1`). The package installs its extension control/SQL files under `/usr/share/postgresql/18/extension/` and is copied to `/share/extension/`. The shared object `asn1oid.so` is copied to `/lib/`.

License declared by package copyright: GPL-3.0-or-later.
The Debian copyright file is included at `/licenses/postgresql-18-asn1oid/copyright` with upstream attribution, packaging terms and component notices.
The referenced full common-license text is copied to `/licenses/GPL-3`.
The CNPG base image provides PostgreSQL and any required system runtime libraries; no additional runtime packages are installed in the final scratch image. If present, the package shared object is copied alongside its control/SQL files, and no external extension shared-library package was identified.
Versioned PostgreSQL and libc base-runtime package dependencies, plus the dynamic-library list, are recorded by suite in `dependency-manifest.json`.
The build also writes `/licenses/runtime-packages.tsv` from installed `dpkg-query` metadata for the extension, PostgreSQL server and Debian package owners of each resolved shared library, so the image carries the exact package and source versions actually used.
The multi-stage Docker build enables signed PGDG source indexes and runs `apt-get source --download-only pgsql-asn1oid=1.6-3.pgdg13+1` on Trixie and `pgsql-asn1oid=1.6-3.pgdg12+1` on Bookworm; both were verified. The exact `.dsc`, upstream orig archive and Debian packaging archive are included in the final image under `/source/` (see `dependency-manifest.json`).


## Commands and results

Package discovery and installation were run in disposable PG18 CNPG containers:

- Trixie amd64: `docker run --rm -i -u root ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie bash -s`, then `apt-get update -qq`, `apt-cache search --names-only '^postgresql-18-asn1oid$'`, `apt-cache policy postgresql-18-asn1oid`, `apt-get install -y --no-install-recommends postgresql-18-asn1oid`, `dpkg-query -W`, `dpkg -L`, and inspection of the installed `.control`, copyright file, and extension `.so` with `ldd` when present. The candidate came from `https://apt.postgresql.org/pub/repos/apt trixie-pgdg/main`.
- Bookworm amd64: same commands in `ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm`; the candidate came from `https://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main`.
- Trixie arm64: `docker run --rm -i --platform linux/arm64 -u root ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie bash -s`, followed by `apt-get update -qq`, `apt-get install -y --no-install-recommends postgresql-18-asn1oid`, `dpkg-query -W`, `dpkg -L`, and control-file inspection. Installed package architecture was arm64 (or `all` for architecture-independent SQL packages).

A disposable PG18/Trixie/amd64 PostgreSQL server installed the package and ran `CREATE EXTENSION asn1oid;` successfully. The functional assertion used by this target's Chainsaw test was run against that server and returned `t`:

```sql
'2.16.840.1.101.3.4.2.1'::asn1oid::text = '2.16.840.1.101.3.4.2.1'
```

The extension-specific Chainsaw suite provisions a fresh CNPG Cluster and Database, then executes the same assertion using an Alpine/psql Job through the Cluster's CNPG-managed service. Integrated results are recorded below.

## Exact Chainsaw fixture rerun (2026-09-29)

Fixture: `test/functional.yaml`, SHA-256 `e19b45be44a4ac4a3f676d85ef8c90e92b1ce1c9837a8b818d43a7cb487c7fbf`. I installed the package from PGDG and created `CREATE EXTENSION asn1oid;` in disposable PG18.6 servers based on `ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm` and `ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie`. I extracted this exact fixture SQL and invoked `docker exec -i simple-ext-fixture-<distro> psql -h 127.0.0.1 -p 55432 -U postgres -d postgres -X -v ON_ERROR_STOP=1 -Atq -c "$TEST_SQL"` for the scalar query (for RUM, passed the exact embedded SQL block from this file to the same `psql` command). Results: Bookworm **PASS** (`t`); Trixie **PASS** (`t`). The fixture's SQL and hash are shown here so the reported result stays tied to the tested file revision:

```sql
SELECT '2.16.840.1.101.3.4.2.1'::asn1oid::text = '2.16.840.1.101.3.4.2.1'
```

## Runtime-library ownership lookup rebuild (2026-09-29)

After adjusting the build to try the original `ldd` path, its resolved realpath, and the realpath with `/usr` stripped (while ignoring `dpkg-query` diversion records), the Bookworm amd64 scratch-image build passed:

```sh
docker build --platform linux/amd64 --progress plain \
  --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm \
  --build-arg PG_MAJOR=18 --build-arg EXT_VERSION=1.6-3.pgdg12+1 \
  -f asn1oid/Dockerfile -t isolated-asn1oid-bookworm:ownerlookup .
```

The built image ID was `sha256:3444201c373c8fba25d2811eeb383a797480ab944d9b46e2bb101b09dca225bc`. I copied `/licenses/runtime-packages.tsv` back from that scratch image; it records `libc6:amd64` `2.36-9+deb12u14` (`glibc` source), `postgresql-18` `18.6-1.pgdg12+2`, and `postgresql-18-asn1oid` `1.6-3.pgdg12+1` (`pgsql-asn1oid` source), with their source versions. This directly verifies the Bookworm `/lib` package-owner fallback that previously failed.

## Integrated validation

`task e2e:test:full TARGET=asn1oid DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
