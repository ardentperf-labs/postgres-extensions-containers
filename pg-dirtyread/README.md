# pg_dirtyread

Read dead but unvacuumed tuples from a PostgreSQL relation. [Upstream documentation](https://github.com/df7cb/pg_dirtyread).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-dirtyread
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pg-dirtyread
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-dirtyread
        reference: ghcr.io/cnpg-extensions/pg-dirtyread:2.8-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-dirtyread-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-dirtyread
  extensions:
  - name: pg_dirtyread
    version: "2"
```

## Operation and privileges

Superuser-only inspection can recover dead tuples that PostgreSQL has not vacuumed. It does not replace backups and may reveal data deleted by application users. The upstream regression test disables autovacuum only on its disposable test tables.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

BSD-3-Clause. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
