# pg_rewrite

Rewrite PostgreSQL tables with less locking. [Upstream documentation](https://github.com/cybertec-postgresql/pg_rewrite).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.
Package and runtime validation results are recorded in [evidence](evidence.md).

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-rewrite
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    shared_preload_libraries: ["pg_rewrite"]
    parameters:
      wal_level: "logical"
      output_plugin_libraries: "pgoutput,test_decoding,pg_rewrite"
    extensions:
    - name: pg-rewrite
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pg-rewrite
        reference: ghcr.io/cnpg-extensions/pg-rewrite:2.2-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-rewrite-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-rewrite
  extensions:
  - name: pg_rewrite
    version: "2.2"
```

## Operation and privileges

Table rewriting needs logical WAL and a free replication slot. Ensure sufficient CNPG data-volume space for both table copies and retained WAL. Remove the old table with SQL after verification; inspect and remove any abandoned inactive replication slots after a failed operation.

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

The PGDG copyright labels its notice(s) `cybertec`. The permission and
disclaimer text matches the [SPDX PostgreSQL license template](https://github.com/spdx/license-list-data/blob/main/json/details/PostgreSQL.json),
which allows copyright-holder substitutions in the disclaimer paragraphs.
The metadata uses that SPDX identifier; the image retains the complete original
package copyright, including every named holder and notice.
