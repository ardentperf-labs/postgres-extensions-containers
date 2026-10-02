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
by default. The vendored upstream PL/Python regression suite is pinned in [test/UPSTREAM](test/UPSTREAM) and selected by [test/run.sh](test/run.sh).

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
licenses and bundled-component notices. The image copies the matching Python
standard library and native modules, with their system libraries under
`/system` when the CNPG base does not already supply them. Package copyright
notices are under `/licenses`. The matching CNPG base supplies glibc and the ELF
loader.

Renovate tracks the PGDG package pin. Rebuild after interpreter, module,
native-library or base-image security updates and rerun both distro regression suites and
architecture builds. SQL catalog version 1.0 is reviewed separately from
package releases.

Maintained by Jeremy Schneider (@ardentperf).
