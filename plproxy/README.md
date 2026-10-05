# plproxy

database partitioning system for PostgreSQL 18. [Upstream documentation](https://plproxy.github.io/).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-plproxy
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: plproxy
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-plproxy
        reference: ghcr.io/cnpg-extensions/plproxy:2.12.0-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-plproxy-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-plproxy
  extensions:
  - name: plproxy
    # renovate: suite=trixie-pgdg depName=postgresql-18-plproxy extractVersion=^(?:[0-9]+:)?(?<version>[0-9]+[.][0-9]+[.][0-9]+)
    version: '2.12.0'
```

## Operation and privileges

PL/Proxy forwards SQL through PostgreSQL connections. Its dynamically linked libpq and transitive libraries are supplied by the matching CNPG minimal base (which includes psql); no runtime installation is needed. Configure connection strings and credentials through SQL and Kubernetes Secrets, and allow only required outbound destinations.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

ISC. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).

PL/Proxy CONNECT strings use libpq keyword/value syntax (for example, `host=cluster-rw dbname=app user=proxy_user`), not connection URIs: the plugin adds connection options to the string. Supply credentials through your deployment Secrets.
