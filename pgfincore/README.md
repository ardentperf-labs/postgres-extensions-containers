# pgfincore

set of PostgreSQL functions to manage blocks in memory. [Upstream documentation](http://villemain.org/projects/pgfincore).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgfincore
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pgfincore
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgfincore
        reference: ghcr.io/cnpg-extensions/pgfincore:1.4.0-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pgfincore-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pgfincore
  extensions:
  - name: pgfincore
    # renovate: suite=trixie-pgdg depName=postgresql-18-pgfincore extractVersion=^(?:[0-9]+:)?(?<version>[0-9]+[.][0-9]+)
    version: '1.4'
```

## Operation and privileges

Administrative functions inspect or advise the operating-system page cache for relation files. Calls are limited by PostgreSQL and container permissions. Optional filesystem export/import features are not supported; use the SQL-returning inspection and cache-advice functions.

## Verify behavior

The vendored upstream suite is pinned in [test/UPSTREAM](test/UPSTREAM) and
invoked by [test/run.sh](test/run.sh).

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture and rerun both distro regression suites. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

BSD-3-Clause. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
