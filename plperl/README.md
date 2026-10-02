# PL/Perl

PostgreSQL's trusted `plperl` and untrusted `plperlu` languages, with the packaged
boolean, hstore and JSONB transforms. One image supplies all eight SQL extensions.

## Supported images

PostgreSQL 18 on Debian Trixie and Bookworm, with amd64 and arm64 build targets.
The extension comes from PGDG's `postgresql-plperl-18` package. Interpreter
libraries and modules are supplied by the image; users do not install packages
inside PostgreSQL containers.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-plperl
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: plperl
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-plperl-18
        reference: ghcr.io/cnpg-extensions/plperl:18.6-18-trixie
      env:
      - name: PERL5LIB
        value: ${image_root}/perl/arch:${image_root}/perl/share:${image_root}/perl/vendor-arch:${image_root}/perl/vendor-share
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-plperl-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-plperl
  extensions:
  - name: plperl
    version: "1.0"
  - name: plperlu
    version: "1.0"
  - name: bool_plperl
    version: "1.0"
  - name: bool_plperlu
    version: "1.0"
  - name: hstore
  - name: hstore_plperl
    version: "1.0"
  - name: hstore_plperlu
    version: "1.0"
  - name: jsonb_plperl
    version: "1.0"
  - name: jsonb_plperlu
    version: "1.0"
```

The transforms are optional. hstore transforms require the `hstore` extension
provided by the PostgreSQL base image. `plperl` is the default extension selected
by the image catalog; add the other SQL extensions in the Database resource when
needed. The vendored upstream PL/Perl regression suite is pinned in [test/UPSTREAM](test/UPSTREAM) and selected by [test/run.sh](test/run.sh).

## Privileges and operation

Trusted PL/Perl restricts available Perl operations. Function authors also need
PostgreSQL language and schema privileges. Untrusted PL/PerlU functions require
superuser authority and run with the PostgreSQL operating-system account's
filesystem and network access. Grant execution of such functions deliberately;
use CNPG-managed PostgreSQL Services for database connections.

The image bundles Perl's core modules plus DBI and DBD::Pg for server integrations
such as Bucardo. Module search paths are relocated through `PERL5LIB`; native
libraries are supplied by the matching CNPG base image. Compiling or installing
extra Perl modules at runtime is unsupported. These examples write no files and
need no extra storage. Custom functions that produce files require an explicit
volume, permissions, retention and cleanup policy.

## Dependencies, licenses and updates

PostgreSQL code uses the PostgreSQL license. Perl, DBI and DBD::Pg retain their
Artistic/GPL alternative notices. The image copies Perl's core and vendor module
trees selected by the distribution's `perl` package, DBI, DBD::Pg, and the PostgreSQL language and transform libraries. Package
copyright notices are under `/licenses`; the matching CNPG base supplies native
runtime libraries, glibc and the ELF loader.

Renovate updates the PGDG package pin. Rebuild after interpreter, module,
native-library or base-image security updates and rerun both distro regression suites and
architecture builds. The catalog version remains 1.0 and must be reviewed
independently of the package version.

Maintained by Jeremy Schneider (@ardentperf).
