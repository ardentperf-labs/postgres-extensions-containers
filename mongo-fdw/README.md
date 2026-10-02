# mongo_fdw

This image is deferred to the final review batch pending an upstream driver bug
report and a corrected Debian binary package. The source-build workaround below
is retained for investigation; it is not the intended release packaging.

mongo_fdw is a PostgreSQL foreign data wrapper for MongoDB. It lets SQL query and modify MongoDB collections through foreign tables. See the [upstream mongo_fdw project](https://github.com/EnterpriseDB/mongo_fdw) for supported options and behavior. The image contains the FDW and its MongoDB C-driver libraries; MongoDB remains a separate outbound data service.

The PGDG package supports PostgreSQL 18 on Trixie only in this matrix. Both amd64 and arm64 packages are published. Bookworm has no PG18 package.

## Install and query a MongoDB collection

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-mongo-fdw
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: mongo-fdw
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-mongo-fdw
        reference: ghcr.io/cnpg-extensions/mongo-fdw:5.5.3-18-trixie
      ld_library_path: [system]
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-mongo-fdw-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-mongo-fdw
  extensions:
  - name: mongo_fdw
    version: '1.1'
~~~

Configure an independently operated MongoDB service and grant the PostgreSQL workload outbound access to it. The SQL below uses a placeholder password. In production, read the password from your secret manager and have a database bootstrap job or other trusted automation run `CREATE USER MAPPING` with that value; rotate it with `ALTER USER MAPPING`. `mongo_fdw` does not read Kubernetes Secrets itself.

~~~sql
CREATE SERVER inventory_mongo
  FOREIGN DATA WRAPPER mongo_fdw
  OPTIONS (address 'mongo.example.internal', port '27017');

CREATE USER MAPPING FOR CURRENT_USER
  SERVER inventory_mongo
  OPTIONS (username 'inventory_reader', password '<password-from-secret-manager>');

CREATE FOREIGN TABLE inventory (
  _id name,
  item text,
  quantity integer
)
SERVER inventory_mongo
OPTIONS (database 'warehouse', collection 'inventory');

SELECT item, quantity
FROM inventory
WHERE quantity > 0;
~~~

The first foreign-table column must map to MongoDB's _id field and use PostgreSQL type name. mongo_fdw supports read/write operations and pushdown subject to the documented driver and MongoDB behavior. It does not support IMPORT FOREIGN SCHEMA because MongoDB is schemaless.

## Package, licensing and updates

PGDG package: 5.5.3-1.pgdg13+1; SQL version: 1.1. The extension is PostgreSQL License and LGPL-3.0; the bundled MongoDB C-driver libraries are Apache-2.0. Copyright notices for the extension and bundled runtime packages are under `/licenses/<package>/`. The image contains no source archives or build patch.

The Trixie `mongo-c-driver` source applies a database-name validation patch whose `mongoc_collection_aggregate()` call passed the collection namespace and database in the wrong order. That makes aggregate scans fail before sending a query. The image rebuilds `libmongoc` from the source version matching the installed runtime package, with a one-line argument-order correction that retains Debian's validation patch. Review the patch when the driver source changes and remove it when the packaged driver includes the correction.

Renovate tracks the PGDG package. Rebuild after package or base-image updates and review the linked runtime libraries and their notices.
