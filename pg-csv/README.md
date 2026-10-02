# pg_csv

Flexible CSV processing for Postgres. [Upstream documentation](https://github.com/PostgREST/pg_csv/).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-csv
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pg-csv
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pg-csv
        reference: ghcr.io/cnpg-extensions/pg-csv:1.0.2-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-csv-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-csv
  extensions:
  - name: pg_csv
    version: "1.0.1"
```

## Operation and privileges

CSV is returned as SQL text; this image supports no server-side CSV file export. Clients own storage and retention of exported results.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

MIT. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
