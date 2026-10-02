# pg_similarity

PostgreSQL similarity functions extension. [Upstream documentation](https://github.com/eulerto/pg_similarity).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-similarity
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pg-similarity
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-similarity
        reference: ghcr.io/cnpg-extensions/pg-similarity:1.0-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-similarity-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-similarity
  extensions:
  - name: pg_similarity
    version: "1.0"
```

## Operation and privileges

Similarity functions execute inside PostgreSQL and require no writable files or external services.

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
