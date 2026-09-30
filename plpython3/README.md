# PL/Python 3

PostgreSQL's untrusted `plpython3u` language and its packaged hstore, JSONB and
ltree transforms. One image supplies all four SQL extensions.

## Supported images and declarative setup

PostgreSQL 18 on Debian Trixie and Bookworm, with amd64 and arm64 build targets.
The extension comes from PGDG's `postgresql-plpython3-18` package. The image
supplies its matching Python interpreter library, standard library and native
modules. No runtime package installation is required.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-plpython3
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: plpython3
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-plpython3-18
        reference: ghcr.io/cnpg-extensions/plpython3:18.6-18-trixie
      ld_library_path: [system]
      env:
      - name: PYTHONHOME
        value: ${image_root}/python
      - name: PYTHONDONTWRITEBYTECODE
        value: "1"
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-plpython3-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-plpython3
  extensions:
  - name: plpython3u
    version: "1.0"
  - name: hstore
  - name: ltree
  - name: hstore_plpython3u
    version: "1.0"
  - name: jsonb_plpython3u
    version: "1.0"
  - name: ltree_plpython3u
    version: "1.0"
```

Transforms are optional; the hstore and ltree transforms require their
corresponding base-image SQL extensions. The image catalog selects `plpython3u`
by default. The [functional SQL](test/functional.sql) checks all transforms,
PostgreSQL SPI queries, compression, hashing, SSL module loading and an in-memory
SQLite query from Python code.

## Privileges and operation

PL/Python 3 is untrusted: creating functions requires superuser authority.
Functions execute with the PostgreSQL operating-system account's filesystem and
network access. Grant function execution deliberately and use CNPG-managed
PostgreSQL Services for incoming database connections.

`PYTHONHOME` relocates the packaged standard library. The image's module tree is
read-only and bytecode writes are disabled. Installing packages with pip or
compiling modules at runtime is unsupported. Extend the build and dependency
accounting for additional modules. These examples produce no files. Custom
file-producing functions need declared storage, permissions, retention and
cleanup, including any temporary files they create.

## Dependencies, licenses and updates

PostgreSQL code uses the PostgreSQL license; Python carries its PSF/Python
licenses and bundled-component notices. Native standard-library dependencies
include compression, SQLite, cryptography, libffi, readline and DBM libraries.
Exact binary/source package versions are recorded in
`/licenses/runtime-packages.tsv`. Every copied package retains its Debian
copyright file and full common license texts. Exact corresponding source
archives and Debian packaging are included under `/source`, with their source
versions in `/licenses/source-packages.tsv`; this covers GPL/LGPL modules too.
The matching CNPG base supplies glibc and the ELF loader; their package versions and the server version are recorded in `/licenses/base-packages.tsv`.

Staging resolves dependencies of every shipped ELF module and fails on missing
libraries or package attribution. Bundled Python modules follow the Python
source package; separately packaged native libraries have their own version
entries. Renovate tracks the PGDG package pin. Rebuild on interpreter, module,
native-library or base-image security updates, inspect the new runtime manifest,
and repeat both distro tests and architecture builds. SQL catalog version 1.0
is reviewed separately from package releases. See [evidence](evidence.md).

Maintained by Jeremy Schneider (@ardentperf).
