# pg_track_settings

PostgreSQL extension tracking of configuration settings. [Upstream documentation](https://powa.readthedocs.io/).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-track-settings
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pg-track-settings
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pg-track-settings
        reference: ghcr.io/cnpg-extensions/pg-track-settings:2.1.2-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-track-settings-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-track-settings
  extensions:
  - name: pg_track_settings
    version: "2.1.2"
```

## Operation and privileges

Snapshots and history are ordinary database tables. Schedule `pg_track_settings_snapshot()` through a SQL scheduler. `pg_track_settings_reset()` clears stored history; archive needed rows and set an explicit retention schedule before running it.

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
