# pgnodemx

capture node OS metrics from PostgreSQL. [Upstream documentation](https://github.com/pgnodemx/pgnodemx).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgnodemx
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    shared_preload_libraries: ["pgnodemx"]
    parameters:
      pgnodemx.kdapi_enabled: "off"
    extensions:
    - name: pgnodemx
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgnodemx
        reference: ghcr.io/cnpg-extensions/pgnodemx:2.0.1-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pgnodemx-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pgnodemx
  extensions:
  - name: pgnodemx
    # renovate: suite=trixie-pgdg depName=postgresql-18-pgnodemx extractVersion=^(?:[0-9]+:)?(?<version>[0-9]+[.][0-9]+)
    version: '2.0'
```

## Operation and privileges

OS metrics reflect the container namespace and delegated cgroups, not necessarily the host. SQL functions require appropriate administrative privileges. Downward API functions are disabled in this example because no pod-info volume is supplied. Cgroup functions depend on available controllers; `/proc` metrics remain useful independently.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

PostgreSQL, Apache-2.0. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
