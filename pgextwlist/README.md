# pgextwlist

PostgreSQL Extension Whitelisting. [Upstream documentation](https://github.com/dimitri/pgextwlist).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.
Package and runtime validation results are recorded in [evidence](evidence.md).

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgextwlist
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    shared_preload_libraries: ["pgextwlist"]
    parameters:
      extwlist.extensions: "dblink"
    extensions:
    - name: pgextwlist
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgextwlist
        reference: ghcr.io/cnpg-extensions/pgextwlist:1.20-18-trixie
```

## Operation and privileges

This module has no CREATE EXTENSION artifact. Its preload hook allows non-superusers to install administrator-allowlisted extensions that normally require superuser privileges; PostgreSQL trusted extensions retain their ordinary permissions. The example allowlists `dblink`, already present in the minimal PostgreSQL image. Optional custom script execution is not configured or supported by this image.

## Verify behavior

The [functional SQL fixture](test/functional.sql) shows the supported behavior and
assertions. The Chainsaw test provisions its own Cluster and Database, connects
through the CNPG read/write Service, and checks the SQL result.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Full installed build-package versions are included in `/licenses/build-packages.tsv`.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture and repeat both distro tests. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

PostgreSQL. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf). See [evidence](evidence.md) for package provenance and validation limits.
