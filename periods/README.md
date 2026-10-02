# periods

PERIODs and SYSTEM VERSIONING for PostgreSQL. [Upstream documentation](https://github.com/xocolatl/periods).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-periods
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: periods
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-periods
        reference: ghcr.io/cnpg-extensions/periods:1.2.3-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-periods-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-periods
  extensions:
  - name: btree_gist
  - name: periods
    version: "1.2"
```

## Operation and privileges

Temporal history uses ordinary PostgreSQL tables on the CNPG data volume. To retire history, suspend system versioning with `periods.drop_system_versioning`, delete expired history rows using SQL, then re-enable versioning. Define your retention interval and execute maintenance through an external SQL scheduler.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

PostgreSQL. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
