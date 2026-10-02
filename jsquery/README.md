# jsquery
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

Adds the jsquery language and GIN indexing support for searching jsonb values. See the [upstream project](https://github.com/postgrespro/jsquery) for its API and release history.

## Use with CloudNativePG

Add this image to a PostgreSQL 18 Cluster on Trixie. Choose the Bookworm image tag when the base image uses Bookworm.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-jsquery
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
    - name: jsquery
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-jsquery
        reference: ghcr.io/cnpg-extensions/jsquery:1.2-18-trixie
```

Install the SQL extension in a database with a CNPG `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-jsquery-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-jsquery
  extensions:
  - ensure: present
    name: jsquery
    version: "1.1"
```

A SQL check that exercises the installed extension is:

```sql
SELECT '{"a": 1}'::jsonb @@ 'a = 1'::jsquery;
```

## Package, dependencies and maintenance

The image installs PGDG package `postgresql-18-jsquery` at the Debian version recorded in `metadata.hcl`. Package updates are tracked by Renovate; review changes against the package's control file and rerun the target's build and upstream regression suite. The package is available for PostgreSQL 18 on both Bookworm and Trixie, amd64 and arm64. It depends on the CNPG PostgreSQL 18 base image and libc; no additional runtime package is installed. The jsquery module uses PostgreSQL licensing. Its Debian copyright file, including upstream attribution and any bundled component notices, is included under `/licenses/`.

The SQL catalog version is maintained separately from the Debian package version; verify `default_version` in the packaged control file when updating the package.
