# PL/Tcl
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

PL/Tcl runs Tcl functions inside PostgreSQL. This image supplies the trusted `pltcl` and untrusted `pltclu` variants with Tcl 8.6's shared library and standard script library. See the [PostgreSQL 18 PL/Tcl documentation](https://www.postgresql.org/docs/18/pltcl.html).

## Use with CloudNativePG

Mount the image into PostgreSQL 18:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pltcl
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
    - name: pltcl
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-pltcl-18
        reference: ghcr.io/cnpg-extensions/pltcl:18.6-18-trixie
      ld_library_path:
      - lib
      env:
      - name: TCL_LIBRARY
        value: /extensions/pltcl/share/tcl8.6
```

Enable trusted PL/Tcl in a database with a `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pltcl-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pltcl
  extensions:
  - ensure: present
    name: pltcl
    version: "1.0"
```

A trusted Tcl function can perform simple computation:

```sql
CREATE FUNCTION tcl_add(a integer, b integer) RETURNS integer
AS $$ return [expr {$1 + $2}] $$ LANGUAGE pltcl;
SELECT tcl_add(19, 23); -- 42
```

`pltcl` uses Tcl's safe interpreter, which omits commands such as `exec` and `open`; it cannot access the host filesystem or launch processes directly. To install the untrusted variant, a superuser runs `CREATE EXTENSION pltclu;`. Only superusers can create `pltclu` functions. Those functions run as the PostgreSQL operating-system user with its available filesystem, process and network access. Review untrusted function code and privileges carefully. The included examples and functional test perform SQL-only work. Before enabling `pltclu` functions that produce persistent files, declaratively provide a volume with suitable ownership/access, retention, and cleanup; the image does not define an application data-storage lifecycle.

The extension configuration adds the image's `/lib` directory to the loader path and sets `TCL_LIBRARY` to the packaged Tcl 8.6 scripts. Users need no package installation or filesystem changes in the database container.

## Package, dependency and license notes

PGDG `postgresql-pltcl-18` provides both language control/SQL sets and `pltcl.so`. Debian `libtcl8.6` is the dynamically linked interpreter, with its script library copied to the extension image. The runtime manifest records exact package/source versions and base library closure at `/licenses/runtime-packages.tsv`. Matching PostgreSQL and Tcl source archives and full copyright/license notices are in `/source/` and `/licenses/`.

Renovate tracks `postgresql-pltcl-18`; Debian Tcl updates are reviewed separately. Rebuild and rerun both trusted and untrusted tests when either changes.

## Contributors

Maintained by [@ardentperf](https://github.com/ardentperf).
