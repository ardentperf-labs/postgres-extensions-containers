# db2fce
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

DB2-compatible SQL functions and types, including date/time helpers in the db2 schema. See the [upstream project](https://github.com/credativ/db2fce) for its API and release history.

## Use with CloudNativePG

Add this image to a PostgreSQL 18 Cluster on Trixie. Choose the Bookworm image tag when the base image uses Bookworm.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-db2fce
spec:
  imageCatalogRef:
    apiGroup: postgresql.cnpg.io
    kind: ClusterImageCatalog
    name: postgresql-minimal-trixie
    major: 18
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: db2fce
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-db2fce
        reference: ghcr.io/cnpg-extensions/db2fce:0.0.17-18-trixie
```

Install the SQL extension in a database with a CNPG `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-db2fce-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-db2fce
  extensions:
  - ensure: present
    name: db2fce
    # renovate: suite=trixie-pgdg depName=postgresql-18-db2fce extractVersion=^(?<version>\d+\.\d+\.\d+)
    version: '0.0.17'
```

A SQL check that exercises the installed extension is:

```sql
SELECT db2.year(date '2026-09-29') = 2026;
```

## Package, dependencies and maintenance

The image installs PGDG package `postgresql-18-db2fce` at the Debian version recorded in `metadata.hcl`. Package updates are tracked by Renovate; review changes against the package's control file and rerun the target's build and upstream regression suite. This is a SQL-only package: it contains control/SQL files and no shared object. The package is available for PostgreSQL 18 on both Bookworm and Trixie, amd64 and arm64. It depends on the CNPG PostgreSQL 18 base image and libc; no additional runtime package is installed. The db2fce module uses PostgreSQL licensing. Its Debian copyright file, including upstream attribution and any bundled component notices, is included under `/licenses/`.

