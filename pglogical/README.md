# pglogical

Logical replication through PostgreSQL connections. [Upstream project](https://github.com/2ndQuadrant/pglogical).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.
Package and runtime validation results are recorded in [evidence](evidence.md).

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pglogical
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    shared_preload_libraries: [pglogical]
    parameters:
      wal_level: logical
      output_plugin_libraries: pgoutput,test_decoding,pglogical_output
    extensions:
    - name: pglogical
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pglogical
        reference: ghcr.io/cnpg-extensions/pglogical:2.4.8-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pglogical-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pglogical
  extensions:
  - name: pglogical
    version: "2.4.8"
```

## Operation and privileges

Create provider and subscriber databases with this extension and matching table
definitions. Both endpoints must use CNPG-managed PostgreSQL Services. Store
connection credentials in Kubernetes Secrets and initialize nodes/subscriptions
from a declarative Job or your deployment system. Administrative setup and
replication roles need the privileges required by pglogical; the test uses a
superuser only inside its disposable fixture cluster. Do not reuse its public
test credentials in a deployment.

Call `pglogical.create_node` for each endpoint, register tables with
`pglogical.replication_set_add_table`, and call `pglogical.create_subscription`
on the subscriber. Set `synchronize_structure := false`. Optional schema
synchronization is unsupported until its temporary-file storage, access,
retention and cleanup are designed. Apply schema changes through your normal
migration process. Initial data synchronization is covered by the test.

The [test Job](test/verify.sh) verifies initial copy and live INSERT, UPDATE,
DELETE and TRUNCATE replication between two databases through the managed
Service. Its setup and SQL fixtures show the exact API calls, then remove the
subscription, nodes and temporary replication role.

Monitor replication lag and retained WAL on the PostgreSQL data volume. Plan
slot limits and disk capacity; remove unused subscriptions with
`pglogical.drop_subscription` and remove unused nodes after their consumers are
stopped. Failed consumers must not retain WAL indefinitely. No extra listener
or container shell setup is required.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Installed extension, libc and libpq versions are included in `/licenses/runtime-packages.tsv`.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture and repeat both distro tests. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

PostgreSQL. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf). See [evidence](evidence.md) for package provenance and validation limits.

The package also includes `pglogical_origin` version 1.0.0, an empty compatibility extension for upgrades from PostgreSQL 9.4. It is not needed for new PostgreSQL 18 replication setups. The functional fixture verifies its installation alongside the main replication tests.
