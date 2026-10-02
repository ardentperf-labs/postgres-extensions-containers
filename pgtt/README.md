# pgtt

PostgreSQL Global Temporary Tables. [Upstream documentation](https://github.com/darold/pgtt/).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgtt
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    parameters:
      session_preload_libraries: "pgtt"
    extensions:
    - name: pgtt
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgtt
        reference: ghcr.io/cnpg-extensions/pgtt:4.6-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pgtt-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pgtt
  extensions:
  - name: pgtt
    version: "4.6.0"
```

## Operation and privileges

Global temporary table definitions are shared, while rows are session-local. Load `pgtt` for each session with the declarative parameter below. Temporary rows live in PostgreSQL-managed temporary storage and are removed at session end; ON COMMIT controls transaction cleanup.

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

ISC. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
