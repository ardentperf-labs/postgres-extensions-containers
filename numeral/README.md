# numeral
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

Provides a compact numeral data type with arithmetic, comparison and bitwise operators. See the [upstream project](https://github.com/df7cb/postgresql-numeral) for its API and release history.

## Use with CloudNativePG

Add this image to a PostgreSQL 18 Cluster on Trixie. Choose the Bookworm image tag when the base image uses Bookworm.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-numeral
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
    - name: numeral
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-numeral
        reference: ghcr.io/cnpg-extensions/numeral:1.3-18-trixie
```

Install the SQL extension in a database with a CNPG `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-numeral-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-numeral
  extensions:
  - ensure: present
    name: numeral
    version: "1"
```

A SQL check that exercises the installed extension is:

```sql
SELECT ('40'::numeral + '2'::numeral) = '42'::numeral;
```

## Package, dependencies and maintenance

The image installs PGDG package `postgresql-18-numeral` at the Debian version recorded in `metadata.hcl`. Package updates are tracked by Renovate; review changes against the package's control file and rerun the target's build. The package is available for PostgreSQL 18 on both Bookworm and Trixie, amd64 and arm64. It depends on the CNPG PostgreSQL 18 base image and libc; no additional runtime package is installed. The numeral module uses GPL-2.0-or-later licensing. Its Debian copyright file is included under `/licenses/`.

