# pg-background
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

[`pg_background`](https://github.com/vibhorkum/pg_background) runs SQL in PostgreSQL background workers and returns completion metadata to the calling session. It does not require `shared_preload_libraries`; preloading is only needed if you want to set its GUCs in server configuration before first use.

## Usage

Add the extension image to a complete Cluster definition:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-background
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
    - name: pg-background
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pg-background
        reference: ghcr.io/cnpg-extensions/pg-background:2.0.3-18-trixie
~~~

Install it in the database with a Database resource:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-background-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-background
  extensions:
  - name: pg_background
    # renovate: suite=trixie-pgdg depName=postgresql-18-pg-background extractVersion=^(?<version>\d+\.\d+)
    version: '2.0'
~~~

A superuser can run work asynchronously and check its result:

~~~sql
SELECT (pg_background_run('SELECT count(*) FROM pg_class')).*;
~~~

The command runs in a separate worker. Grant only the privileges needed by the SQL being run; background execution does not bypass PostgreSQL authorization.

## Supported matrix and licenses

The image supports PostgreSQL 18 on Debian Bookworm and Trixie. Package copyright is included under `/licenses/postgresql-18-pg-background/`, and `/licenses/runtime-packages.tsv` records the exact installed extension and runtime package versions. PGDG package updates are tracked by Renovate.
