# PL/JS
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

PL/JS provides a trusted JavaScript procedural language for PostgreSQL, backed by QuickJS statically compiled into `pljs.so`. See the [upstream project](https://github.com/plv8/pljs) for its API and release history.

## Use with CloudNativePG

Mount the extension image into PostgreSQL 18:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pljs
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
    - name: pljs
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pljs
        reference: ghcr.io/cnpg-extensions/pljs:1.0.5-18-trixie
```

Install PL/JS in a database with a `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pljs-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pljs
  extensions:
  - ensure: present
    name: pljs
    # renovate: suite=trixie-pgdg depName=postgresql-18-pljs extractVersion=^(?<version>\d+\.\d+\.\d+)
    version: '1.0.5'
```

A function exercises the JavaScript runtime:

```sql
CREATE FUNCTION js_double(a integer) RETURNS integer
LANGUAGE pljs AS $$ return a * 2; $$;
SELECT js_double(21); -- 42
```

The language is trusted, but the extension itself must be installed by a database superuser. Continue to apply PostgreSQL's normal function and schema privileges to JavaScript functions. The included example performs SQL-only work. The vendored upstream suite is pinned in [test/UPSTREAM](test/UPSTREAM) and
invoked by [test/run.sh](test/run.sh). If application functions are extended to write files through other installed interfaces, declaratively provide a volume with suitable ownership/access, retention, and cleanup before enabling that workflow.

## Package, dependency and license notes

PGDG package `postgresql-18-pljs` supplies `pljs.so` and its control/SQL files. QuickJS is statically linked, so no additional runtime package is needed. The PGDG package copyright notice is under `/licenses`.

PLJS uses a project-specific license recorded as `LicenseRef-PLJS` in the image metadata. The Debian copyright file preserves its full terms; QuickJS is MIT licensed. Renovate tracks `postgresql-18-pljs`; inspect the source patch and notices when updating it.

## Contributors

Maintained by [@ardentperf](https://github.com/ardentperf).
