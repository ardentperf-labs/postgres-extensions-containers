# mysql_fdw
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

[mysql_fdw](https://github.com/EnterpriseDB/mysql_fdw) is a PostgreSQL Foreign Data Wrapper (FDW) that enables PostgreSQL to query MySQL and MariaDB databases. It allows you to define foreign tables in PostgreSQL that map to MySQL/MariaDB tables and query them using standard SQL.

## Usage

### 1. Add the mysql-fdw extension image to your Cluster

Define the `mysql-fdw` extension under the `postgresql.extensions` section of
your `Cluster` resource. For example:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-mysql-fdw
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1

  storage:
    size: 1Gi

  postgresql:
    extensions:
    - name: mysql-fdw
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-mysql-fdw
        reference: ghcr.io/cnpg-extensions/mysql-fdw:2.9.3-18-trixie
      ld_library_path: [system]
```

### 2. Enable the extension in a database

You can install `mysql_fdw` in a specific database by creating or updating a
`Database` resource, or by running `CREATE EXTENSION` directly in `psql`. For example, to enable it in the `app` database:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-mysql-fdw-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-mysql-fdw
  extensions:
  - name: mysql_fdw
    # SQL version cannot be updated by Renovate; if it changes, manually update mysql-fdw/README.md, mysql-fdw/metadata.hcl, and renovate.json.
    version: '1.2'
```
Alternatively, you can enable the extension directly with SQL:

```sql
CREATE EXTENSION mysql_fdw;
```

### 3. Verify installation

Once the database is ready, connect to it with `psql` and run:

```sql
\dx
```

You should see `mysql_fdw` listed among the installed extensions.

## Phase 04 backlog: restore stock CNPG compatibility

Status: deferred pending a runtime lookup fix. Track this work with the
[phase-04 direct-dependencies branch in Extension Backlog #291](https://github.com/cnpg-extensions/postgres-extensions-containers/issues/291)
and [runtime failure #11](https://github.com/ardentperf-labs/postgres-extensions-containers/issues/11).
The separate `fix/remove-mysql-fdw` branch removes the broken recipe from main.
When rebasing this stack after that removal, retain this follow-up and restore
MySQL FDW only once the acceptance checks below pass; do not accidentally
reintroduce the unchanged recipe from an older stack layer.

A live foreign-table query fails even though CREATE EXTENSION and CNPG Database
reconciliation succeed. The module calls `get_share_path(my_exec_path, ...)`
and opens `/usr/share/postgresql/18/extension/mysql_fdw_pushdown.config`.
The shipped file is instead mounted at
`/extensions/mysql-fdw/share/extension/mysql_fdw_pushdown.config`.

- [ ] Implement a lookup that works with stock CNPG PostgreSQL images. Evaluate
  following PostgreSQL 18's `extension_control_path` discovery policy or locating
  the config relative to the loaded module. No approach has been selected.
  The existing `get_share_path()` does not consult that setting; CNPG's read-only
  root filesystem prevents a bootstrap command from creating a symlink at the
  expected installation path.
- [ ] Preserve the MariaDB client library, compatibility alias, license evidence,
  and the shared build/release acceptance gates. Prefer an upstream-supported
  fix; document any actual source workaround and its removal condition.
- [ ] Run a real foreign-table query against an isolated MySQL/MariaDB fixture
  through the extension image mounted in stock CNPG. The vendored runner in
  `test/run.sh` requires `MYSQL_HOST` and otherwise exits 77; its presence does
  not establish live-query coverage. Ensure the required validation supplies
  the fixture and executes the queries rather than skipping them.
- [ ] Validate supported PostgreSQL/distribution/architecture combinations and
  config lookup after pod replacement. If the chosen solution supports arbitrary
  extension mount names, include a renamed mount in validation.

No lookup fix or new runtime validation is included in this backlog update.

## Known Caveats

- **MySQL/MariaDB client library**: The extension uses `dlopen()` at runtime to
  load `libmysqlclient.so`. This library is not detected by `ldd`, so it is
  explicitly bundled in the image as `libmariadb.so.3` with a `libmysqlclient.so`
  compatibility symlink. Only MariaDB-compatible clients are tested.
- **Foreign queries currently fail on stock CNPG**: A live query exposed the
  pushdown-config lookup mismatch described above. Installation-only checks do
  not detect it. Reintroduction is blocked on the phase-04 acceptance checks.
- **License**: The `mysql_fdw` extension is BSD-3-Clause, but its runtime
  dependency `libmariadb3` is LGPL-2.1, which is why this extension is hosted
  in the CNPG Extensions project rather than upstream.

## Contributors

This extension is maintained by:

- Jeremy Schneider (@ardentperf)

The maintainers are responsible for:

- Monitoring upstream releases and security vulnerabilities.
- Ensuring compatibility with supported PostgreSQL versions.
- Reviewing and merging contributions specific to this extension's container
  image and lifecycle.

---

## Licenses and Copyright

This container image contains software that may be licensed under various
open-source licenses.

All relevant license and copyright information for the `mysql-fdw` extension
and its dependencies are bundled within the image at:

```text
/licenses/
```

By using this image, you agree to comply with the terms of the licenses
contained therein.
