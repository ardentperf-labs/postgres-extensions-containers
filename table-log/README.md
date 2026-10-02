# table_log

log changes on tables and restore tables to point in time. [Upstream documentation](https://github.com/df7cb/table_log).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-table-log
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: table-log
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-tablelog
        reference: ghcr.io/cnpg-extensions/table-log:0.6.4-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-table-log-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-table-log
  extensions:
  - name: table_log
    version: "0.6.1"
```

## Operation and privileges

Row-change audit records are ordinary database tables on the CNPG data volume. Protect log tables from application writes. Define retention and delete expired audit rows through SQL using the log timestamp column; normal VACUUM reclaims space. No external log file is used.

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

LicenseRef-table-log. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
