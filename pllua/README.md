# PL/Lua
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

PL/Lua embeds Lua 5.3 in PostgreSQL. The package provides trusted `pllua`, untrusted `plluau`, and optional hstore transform extensions. See the [PL/Lua reference](https://pllua.github.io/pllua/).

## Use with CloudNativePG

Mount the image into PostgreSQL 18:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pllua
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
    - name: pllua
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pllua
        reference: ghcr.io/cnpg-extensions/pllua:1-2.0.12-18-trixie
      ld_library_path:
      - lib
```

Enable trusted PL/Lua with a `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pllua-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pllua
  extensions:
  - ensure: present
    name: pllua
    version: "2.0"
```

Use a trusted Lua function:

```sql
CREATE FUNCTION lua_add(a integer, b integer) RETURNS integer
LANGUAGE pllua AS $$ return a + b $$;
SELECT lua_add(19, 23); -- 42
```

`pllua` runs inside a sandbox that exposes safe Lua operations; for example, `os.execute` is absent there. To install the untrusted language, a superuser runs `CREATE EXTENSION plluau;`. Only superusers can create `plluau` functions. The untrusted interpreter exposes Lua's operating-system functions, which run with PostgreSQL's operating-system account and its filesystem/network permissions. Do not grant `EXECUTE` on such functions without reviewing their code and effects. Optional `hstore_pllua` and `hstore_plluau` transforms require the `hstore` extension supplied by the matching CNPG PostgreSQL base image. The included example and functional test perform SQL-only work. Before enabling `plluau` functions that produce persistent files, declaratively provide a volume with suitable ownership/access, retention, and cleanup; the image does not define an application data-storage lifecycle.

## Package and dependency notes

The image contains the PGDG extension modules/control/SQL files and Debian `liblua5.3-0` copied into `/lib`. The extension is dynamically linked to Lua 5.3; the matching Lua runtime and base system library versions are recorded in `/licenses/runtime-packages.tsv`. Exact PGDG PL/Lua and Debian Lua source packages, package copyright, and license notices are included under `/source/` and `/licenses/`.

Renovate tracks `postgresql-18-pllua`. Review the separately versioned Lua package and rerun trusted/untrusted tests when rebuilding after either package changes.

## Contributors

Maintained by [@ardentperf](https://github.com/ardentperf).
