# PL/Perl implementation evidence

Inspected 2026-09-29 in disposable CNPG PG18 minimal containers on amd64.

| Suite | PGDG package | Catalog versions |
|---|---|---|
| Trixie | postgresql-plperl-18 18.6-1.pgdg13+2 | all eight extensions 1.0 |
| Bookworm | postgresql-plperl-18 18.6-1.pgdg12+2 | all eight extensions 1.0 |

Both suites: APT policy/search, actual installation, dpkg payload listing,
control files and native dependency inspection passed. Commands and output are
recorded under `evidence/<suite>/package-inspection.txt`. The package was
scaffolded with the documented Dagger scaffolder before replacing its generated
placeholders and correcting the custom package-name mapping.

Direct `docker build -f plperl/Dockerfile --build-arg PG_MAJOR=18
--build-arg EXT_VERSION=<suite version> --build-arg BASE=<matching CNPG minimal
image>` passed for both suites on amd64. Exported each scratch image's payload
and mounted it read-only at `/extensions/plperl` in a fresh matching CNPG minimal
container. With the README's library and Perl module paths, PostgreSQL created
both languages and all six transforms. `test/functional.sql` passed: uppercase
function, JSONB/hstore/boolean results in both languages, and DBI/DBD::Pg native
driver loading. No runtime packages were installed in the mounted-image tests.

Exact redistributed package/source manifests from those builds are recorded per
suite and are also shipped in the images. Sources include their original archives
and Debian packaging. Perl core modules are versioned with the Perl source;
DBI/DBD::Pg are separate packages. The PostgreSQL package supplies the language
and transform modules. Dynamic closure is computed from every native module.

Standalone loading above is separate from the integrated validation below.

## Integrated validation

`task e2e:test:full TARGET=plperl DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
