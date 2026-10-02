# pgTAP

Unit testing framework extension for PostgreSQL 18. [Upstream documentation](https://pgtap.org/).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgtap
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pgtap
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgtap
        reference: ghcr.io/cnpg-extensions/pgtap:1.3.4-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pgtap-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pgtap
  extensions:
  - name: pgtap
    # renovate: suite=trixie-pgdg depName=postgresql-18-pgtap extractVersion=^(?:[0-9]+:)?(?<version>[0-9]+[.][0-9]+[.][0-9]+)
    version: '1.3.4'
```

## Operation and privileges

The server-side TAP assertion functions return text through SQL. Test runners remain separate clients connected to the CNPG-managed endpoint; they own report files and retention.

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
