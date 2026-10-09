# pg_permissions

see all permissions in a PostgreSQL database. [Upstream documentation](https://github.com/cybertec-postgresql/pg_permissions).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-permissions
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pg-permissions
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pg-permissions
        reference: ghcr.io/cnpg-extensions/pg-permissions:1.4.1-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-permissions-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-permissions
  extensions:
  - name: pg_permissions
    # renovate: suite=trixie-pgdg depName=postgresql-18-pg-permissions extractVersion=^(?:[0-9]+:)?(?<version>[0-9]+[.][0-9]+)
    version: '1.4'
```

## Operation and privileges

Permissions are exposed through SQL views in the extension installation schema. Restrict access to administrative roles when object or role names are sensitive.

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

The PGDG copyright labels its notice(s) `CYBERTEC`. The permission and
disclaimer text matches the [SPDX PostgreSQL license template](https://github.com/spdx/license-list-data/blob/main/json/details/PostgreSQL.json),
which allows copyright-holder substitutions in the disclaimer paragraphs.
The metadata uses that SPDX identifier; the image retains the complete original
package copyright, including every named holder and notice.
