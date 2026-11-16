# Additional Debian extension backlog

These placeholders extend [Extension Backlog #291](https://github.com/cnpg-extensions/postgres-extensions-containers/issues/291).
They record candidates found in the 2026-11-16 PGDG Bookworm/Trixie package
inventory, not accepted or validated implementations. Carry this file forward
when rebasing the remaining stack. pg_textsearch is deliberately excluded.

## Phase 04: runtime dependencies and operational integration

- [ ] **pg_stat_tcpinfo** (`postgresql-18-pg-stat-tcpinfo`): being extracted with
  **pgfaceting** into a standalone addition branch. Keep both out of subsequent
  backlog PRs once that addition merges; rebase onto the resulting main.
- [ ] **bgw_replstatus** (`postgresql-18-bgw-replstatus`): review preload setup,
  role-probe TCP port exposure, network policy, and usefulness alongside CNPG.
- [ ] **pgauditlogtofile** (`postgresql-18-pgauditlogtofile`): depends on pgAudit;
  validate writable log storage, permissions, rotation and retention.
- [ ] **address_standardizer** (`postgresql-18-address-standardizer`): inspect
  every packaged control file and data payload; validate address parsing and
  PCRE runtime dependencies. Check upstream PostGIS catalog ownership first.
- [ ] **postgis_tiger_geocoder** (`postgresql-18-postgis-tiger-geocoder`): inspect
  PostGIS dependencies, data-loading requirements and usable geocoding examples;
  check upstream PostGIS catalog ownership before creating a separate image.
- [ ] **pg_failover_slots** (`postgresql-18-pg-failover-slots`): assess interaction
  with CNPG and PostgreSQL's native slot synchronization before considering it.
- [ ] **pg_auto_failover** (`postgresql-18-auto-failover`): assess whether any
  server component is useful without competing with CNPG's HA controller.
- [ ] **repmgr** (`postgresql-18-repmgr`): same HA ownership review; do not deploy
  a second failover manager inside the PostgreSQL container.
- [ ] **Pgpool modules** (`postgresql-18-pgpool2`): separate server modules from
  the external Pgpool service; inventory libpgpool dependencies and validate a
  real external-service integration.

## Phase 06: foreign servers and external database fixtures

- [ ] **oracle_fdw** (`postgresql-18-oracle-fdw`): resolve Oracle client
  availability and redistribution terms under the repository licensing policy,
  then test real Oracle foreign queries. No licensing exception is approved.

MySQL FDW remains deferred under the [phase-04 checklist](mysql-fdw/README.md#phase-04-backlog-restore-stock-cnpg-compatibility).
Mongo FDW and DocumentDB remain in their existing phase-06 branch.

## Inventory exclusions

`postgresql-18-jit` is a PostgreSQL runtime component, while `pg-catcheck` and
`pg-checksums` are external commands. They are not extension-image candidates.
The PostGIS and pgRouting `-scripts` packages are companion payloads already
installed by their upstream recipes, not missing independent extensions.
Older-version-only packages (`pg-fact-loader`, `pgl-ddl-deploy`,
`pglogical-ticker`, `slony1-2`, and OmniDB) need PG18 package availability before
they can enter this repository's supported extension backlog.
