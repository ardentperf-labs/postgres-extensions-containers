# DocumentDB PostgreSQL extension

DocumentDB is a MongoDB-compatible document database built on PostgreSQL. This image supplies the PostgreSQL extension payload for BSON and document operations. See the [upstream DocumentDB project](https://github.com/microsoft/documentdb) for the broader architecture and gateway. It does not include the separate Mongo wire-protocol gateway or open an incoming listener; applications connect through the CNPG-managed PostgreSQL Service and use PostgreSQL SQL.

This package currently supports PostgreSQL 18 on Trixie only. PGDG publishes both amd64 and arm64 packages. Bookworm has no PG18 package.

## Install with CloudNativePG

The DocumentDB extension depends on pg_cron, pgvector, PostGIS and the PostgreSQL core tsm_system_rows extension. Its package also depends on RUM for the optional DocumentDB extended-RUM component. The examples use matching PG18/Trixie images; keep dependency image versions aligned with the PostgreSQL major and suite.

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-documentdb
spec:
  enableSuperuserAccess: true
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    shared_preload_libraries:
    - pg_documentdb
    - pg_documentdb_core
    - pg_documentdb_extended_rum
    - pg_cron
    parameters:
      cron.database_name: app
      documentdb.localhost_connection_string: "host=/controller/run"
    extensions:
    - name: pgvector
      image:
        reference: ghcr.io/cloudnative-pg/pgvector:0.8.6-18-trixie
      ld_library_path: [system]
    - name: postgis
      image:
        reference: ghcr.io/cloudnative-pg/postgis-extension:3.6.4-18-trixie
      ld_library_path: [system]
    - name: pg-cron
      image:
        reference: ghcr.io/cnpg-extensions/pg-cron:1.6.8-18-trixie
    - name: rum
      image:
        reference: ghcr.io/cnpg-extensions/rum:1.3.15-18-trixie
    - name: documentdb
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-documentdb
        reference: ghcr.io/cnpg-extensions/documentdb:1.0-18-trixie
      ld_library_path: [system]
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-documentdb-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-documentdb
  extensions:
  - name: documentdb_core
    version: '1.0-0'
  - name: pg_cron
    version: '1.6'
  - name: tsm_system_rows
    version: '1.0'
  - name: vector
    version: '0.8.6'
  - name: postgis
    version: '3.6.4'
  - name: rum
    version: '1.3'
  - name: documentdb
    # The catalog version differs from the Debian package version.
    version: '1.0-0'
  - name: documentdb_extended_rum
    version: '1.0-0'
~~~

The image metadata preloads `pg_documentdb`, `pg_documentdb_core`, `pg_documentdb_extended_rum` and `pg_cron`, sets `cron.database_name` to `app`, and sets `documentdb.localhost_connection_string` to CNPG's `/controller/run` Unix socket. DocumentDB uses libpq for some operations that must run outside the calling transaction; the socket routes those self-connections through CNPG's existing local peer authentication instead of TCP password authentication. It does not add or widen any `pg_hba.conf` rule. If the PostgreSQL image/operator uses a different Unix socket directory, set the GUC to `host=<socket-directory>` for that deployment. The image supports the `documentdb`, `documentdb_core` and optional `documentdb_extended_rum` SQL extensions. The PGDG `documentdb_distributed` control, SQL files and library are omitted because that component requires Citus, for which this catalog has no compatible dependency image. The separate Mongo wire-protocol gateway is also outside this image.

The optional extended-RUM component is installed after the main DocumentDB extension. It provides a DocumentDB-specific RUM access method for BSON indexes; the functional fixture creates and verifies such an index.

For this CNPG setup, use an administrator-authenticated SQL session and switch to the application role for document operations. Grant the DocumentDB administrator role to `app` from that administrator session, then set the effective role to `app`:

~~~sql
GRANT documentdb_admin_role TO app;
SET ROLE app;
~~~

The `session_user` must remain `postgres` for DocumentDB's internal self-connections to use CNPG's local peer mapping, while `current_user` is `app` for DocumentDB privilege checks. A direct SQL session authenticated as `app` is not supported by this setup: an internal connection would request peer authentication as `app`, while CNPG runs PostgreSQL as the operating-system user `postgres`. This example does not add a trust rule or provide an app password to the internal libpq connection. The Mongo wire-protocol gateway has its own authentication path and is outside this extension image.

A native SQL document lifecycle can be checked by creating a collection, inserting a BSON document, querying it and then updating it:

~~~sql
SELECT documentdb_api.create_collection('app', 'people');
SELECT documentdb_api.insert_one(
  'app', 'people',
  documentdb_core.bson_json_to_bson('{"_id":"ada","name":"Ada","rank":7}')
);
SELECT documentdb_core.bson_get_value_text(document, 'name') AS name,
       documentdb_core.bson_get_value_text(document, 'rank') AS rank
FROM documentdb_api.collection('app', 'people');
SELECT documentdb_api.update(
  'app',
  documentdb_core.bson_json_to_bson(
    '{"update":"people","updates":[{"q":{"_id":"ada"},"u":{"$set":{"rank":8}}}]}'
  )
);
SELECT documentdb_core.bson_get_value_text(document, 'rank') AS updated_rank
FROM documentdb_api.collection('app', 'people');
~~~

The SQL API returns the inserted document and then the updated rank. Use DocumentDB's external gateway separately when clients need the MongoDB wire protocol.

## Package, licensing and updates

The PGDG package is 1.0~RC1-1.pgdg13+1; `documentdb`, `documentdb_core` and `documentdb_extended_rum` each have SQL catalog version 1.0-0. The main API uses Expat/MIT and Apache-2.0 code, and extended RUM uses the PostgreSQL license. The package's exact source archive is bundled under `/source`; it includes the omitted distributed component's AGPL-3.0-or-later source, so the image metadata records that license as well. Complete package copyright and common license texts are included under `/licenses`. Exact runtime package versions and architectures are listed in `/licenses/runtime-packages.txt`. The RUM dependency image carries its own licenses.

Renovate tracks the PGDG package. Rebuild the image after package or base-image security updates; inspect the shipped runtime manifest and rebuild if a linked library changes.
