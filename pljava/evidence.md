# Package and runtime evidence: PL/Java

Checked 2026-09-29 against the PGDG Bookworm and Trixie indexes for PG18. Upstream: https://github.com/tada/pljava. Image uses `postgresql-18-pljava` plus `postgresql-pljava-common`, which carries `pljava.policy`.

| Suite | Extension package | Companion | Java runtime |
|---|---|---|---|
| Bookworm amd64 | `1.6.10-1.pgdg12+1` (`postgresql-pljava` source) | `1.6.10-1.pgdg12+1` | `openjdk-17-jre-headless` `17.0.20.1+1-1~deb12u1` |
| Trixie amd64 | `1.6.10-1.pgdg13+1` (`postgresql-pljava` source) | `1.6.10-1.pgdg13+1` | `openjdk-21-jre-headless` `21.0.12.1+1-1~deb13u1` |

The packages were installed in disposable `ghcr.io/cloudnative-pg/postgresql:18-minimal-{bookworm,trixie}` containers from `bookworm-pgdg/main` and `trixie-pgdg/main`. `dpkg -L` and the installed control/catalog SQL were inspected; the extension installs `pljava.control`, SQLJ catalog scripts and `libpljava-so-1.6.10.so`. The companion supplies `/etc/postgresql-common/pljava.policy`. The image copies these files, both PL/Java JARs, the selected full headless JRE, and the default policy to image-volume locations used by the metadata settings.

The JRE's GPL-2 with Classpath Exception terms and source package are carried in the final image: the builder obtains the exact source versions reported by `dpkg-query` for `postgresql-18-pljava`, `postgresql-pljava-common`, and the selected JRE. The resulting `.dsc` and source archives are copied under `/source/`; Debian package copyright files and full `/licenses/GPL-2` are included. PL/Java itself is BSD-3-Clause. `/licenses/runtime-packages.tsv` is generated from installed package/source metadata for the extension, server, JRE, JVM, and all `ldd` library owners, including the concrete versions used. Java 17/21 are chosen because PL/Java's policy enforcement requires `-Djava.security.manager=allow` on Java 18–23 and is unavailable starting with Java 24; this build sets that option and points to the packaged policy.

## Functional fixture results

The following exact `test/sql.yaml` fixture was extracted with `yaml.safe_load`, after creating `pljava` in a fresh database, and executed as PostgreSQL superuser with `psql -X -h 127.0.0.1 -p 55432 -v ON_ERROR_STOP=1 -f /tmp/pljava-functional.sql` inside each disposable package-install container. It invokes `java.lang.Integer.sum` and verifies the `java`/`javau` trust flags with NULL-safe assertions.

- Fixture SHA-256: `789f35502523c69fda2a338bcc40bbd78ea4b79d9467968f91baa536d019e85c`.
- Bookworm amd64, PG18.6: **PASS** (`CREATE FUNCTION`, `DO`).
- Trixie amd64, PG18.6: **PASS** (`CREATE FUNCTION`, `DO`).

These package-install tests are separate from the image-build and CNPG operator results recorded below.

## Scratch image and mounted-volume verification

Both direct scratch image builds completed on amd64 with PostgreSQL 18 base images:

```sh
docker build --platform linux/amd64 --progress plain \
  --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm \
  --build-arg PG_MAJOR=18 --build-arg EXT_VERSION=1.6.10-1.pgdg12+1 \
  -f pljava/Dockerfile -t isolated-pljava-bookworm:closure2 .
docker build --platform linux/amd64 --progress plain \
  --build-arg BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie \
  --build-arg PG_MAJOR=18 --build-arg EXT_VERSION=1.6.10-1.pgdg13+1 \
  -f pljava/Dockerfile -t isolated-pljava-trixie:closure3 .
```

Bookworm image ID: `sha256:12f0df44dcbe90e8e8370db3768a38958c6af4f7ca3c33d3c142d7360f675146`.
Trixie image ID: `sha256:328df84ba042be6801931cbd2216d943507683cf7443dadfebfd68da1d1f98d4`.
The tested images ship `/licenses/runtime-packages.tsv`, the complete common-license directory, 13/14 redistributed-package copyright notices, and 44/47 source archive files respectively. Tracked suite-specific `evidence/{bookworm,trixie}/runtime-packages.tsv` files preserve the full binary/source package closure, and `source-packages.tsv` records the exact source packages for every redistributed package.

For a mounted-layout smoke test, the scratch image contents were staged under `/extensions/pljava` in fresh CNPG base containers `ghcr.io/cloudnative-pg/postgresql:18-minimal-bookworm` and `ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie`. PostgreSQL was initialized as the `postgres` OS user with `initdb -D /tmp/pljava-e2e -A trust --no-locale`; the config set `extension_control_path='/extensions/pljava/share:$system'`, `dynamic_library_path='/extensions/pljava/lib:$libdir'`, the four documented PL/Java GUC values (using `-Djava.security.manager=allow`), and `LD_LIBRARY_PATH=/extensions/pljava/jvm/lib/server:/extensions/pljava/jvm/lib:/extensions/pljava/lib`. On each server, `psql -XAt -h 127.0.0.1 -p <55439|55440> -U postgres -d postgres -v ON_ERROR_STOP=1` ran `CREATE EXTENSION pljava`, created `java_add(integer,integer)` from `java.lang.Integer.sum`, and returned `42` for `java_add(19,23)`. **PASS** on Bookworm and Trixie. `ldd` resolved all 37 Bookworm and 38 Trixie JVM/extension ELF objects with no `not found` dependencies. This verifies image-volume paths against fresh base containers; operator/Chainsaw results are recorded separately below.

The README and metadata now set `-Djava.io.tmpdir=/controller/tmp`, matching CNPG's pod scratch location. This temporary-path setting was added after the standalone mounted-layout smoke test above; the operator tests below ran with this configuration and CNPG's scratch volume. The fixture remains SQL-only and does not write persistent application files.

## Integrated validation

`task e2e:test:full TARGET=pljava DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
