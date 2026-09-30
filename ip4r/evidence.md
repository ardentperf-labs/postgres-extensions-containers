# Package and runtime evidence: ip4r

Checked 2026-09-29 against PGDG's live APT indexes. Upstream homepage: https://github.com/RhodiumToad/ip4r. PG18 package: `postgresql-18-ip4r`; source package: `ip4r` (Bookworm `2.4.3-1.pgdg12+2`, Trixie `2.4.3-1.pgdg13+2`). The historical audit records PG18 availability on both architectures for Bookworm and Trixie.

| Debian suite | PGDG package version | Index source |
|---|---|---|
| Bookworm | `2.4.3-1.pgdg12+2` | `https://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main` |
| Trixie | `2.4.3-1.pgdg13+2` | `https://apt.postgresql.org/pub/repos/apt trixie-pgdg/main` |

The PG18 control file is `ip4r.control` (SQL name `ip4r`, default version `2.4`). The package installs its extension control/SQL files under `/usr/share/postgresql/18/extension/` and is copied to `/share/extension/`. The shared object `ip4r.so` is copied to `/lib/`.

License declared by package copyright: PostgreSQL.
The Debian copyright file is included at `/licenses/postgresql-18-ip4r/copyright` with upstream attribution, packaging terms and component notices.
The CNPG base image provides PostgreSQL and any required system runtime libraries; no additional runtime packages are installed in the final scratch image. If present, the package shared object is copied alongside its control/SQL files, and no external extension shared-library package was identified.
Versioned PostgreSQL and libc base-runtime package dependencies, plus the dynamic-library list, are recorded by suite in `dependency-manifest.json`.
The build also writes `/licenses/runtime-packages.tsv` from installed `dpkg-query` metadata for the extension, PostgreSQL server and Debian package owners of each resolved shared library, so the image carries the exact package and source versions actually used.


## Commands and results

Package discovery and installation were run in disposable PG18 CNPG containers:

- Trixie amd64: `docker run --rm -i -u root ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie bash -s`, then `apt-get update -qq`, `apt-cache search --names-only '^postgresql-18-ip4r$'`, `apt-cache policy postgresql-18-ip4r`, `apt-get install -y --no-install-recommends postgresql-18-ip4r`, `dpkg-query -W`, `dpkg -L`, and inspection of the installed `.control`, copyright file, and extension `.so` with `ldd` when present. The candidate came from `https://apt.postgresql.org/pub/repos/apt trixie-pgdg/main`.
- Bookworm amd64: same commands in `ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm`; the candidate came from `https://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main`.
- Trixie arm64: `docker run --rm -i --platform linux/arm64 -u root ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie bash -s`, followed by `apt-get update -qq`, `apt-get install -y --no-install-recommends postgresql-18-ip4r`, `dpkg-query -W`, `dpkg -L`, and control-file inspection. Installed package architecture was arm64 (or `all` for architecture-independent SQL packages).

A disposable PG18/Trixie/amd64 PostgreSQL server installed the package and ran `CREATE EXTENSION ip4r;` successfully. The functional assertion used by this target's Chainsaw test was run against that server and returned `t`:

```sql
'192.168.1.1'::ip4::text = '192.168.1.1'
```

The extension-specific Chainsaw suite provisions a fresh CNPG Cluster and Database, then executes the same assertion using an Alpine/psql Job through the Cluster's CNPG-managed service. Integrated results are recorded below.

## Exact Chainsaw fixture rerun (2026-09-29)

Fixture: `test/functional.yaml`, SHA-256 `e4f6f476145d8da5766f2b101bcbd63e8ec68c596ad6bec2c4f6be1971fcefb3`. I installed the package from PGDG and created `CREATE EXTENSION ip4r;` in disposable PG18.6 servers based on `ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm` and `ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie`. I extracted this exact fixture SQL and invoked `docker exec -i simple-ext-fixture-<distro> psql -h 127.0.0.1 -p 55432 -U postgres -d postgres -X -v ON_ERROR_STOP=1 -Atq -c "$TEST_SQL"` for the scalar query (for RUM, passed the exact embedded SQL block from this file to the same `psql` command). Results: Bookworm **PASS** (`t`); Trixie **PASS** (`t`). The fixture's SQL and hash are shown here so the reported result stays tied to the tested file revision:

```sql
SELECT '192.168.1.1'::ip4::text = '192.168.1.1'
```

## Integrated validation

`task e2e:test:full TARGET=ip4r DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
