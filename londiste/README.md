# Londiste SQL
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

Database-side SQL support for Londiste trigger-based replication. [Upstream project](https://github.com/pgq/londiste-sql).

## Usage

Install the server SQL stack through CNPG extension images:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-londiste
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
    - name: pgq
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgq3
        reference: ghcr.io/cnpg-extensions/pgq:3.5.1-18-trixie
    - name: pgq-node
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgq-node
        reference: ghcr.io/cnpg-extensions/pgq-node:3.5-18-trixie
    - name: londiste
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-londiste-sql
        reference: ghcr.io/cnpg-extensions/londiste:3.8-18-trixie
~~~

Install the SQL stack in a Database:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-londiste-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-londiste
  extensions:
  - name: pgq
    version: '3.5.1'
  - name: pgq_node
    version: '3.5'
  - name: londiste
    # renovate: suite=trixie-pgdg depName=postgresql-18-londiste-sql extractVersion=^(?<version>\d+\.\d+)
    version: '3.8'
~~~

Run the external Londiste client/daemon and PGQ ticker against CNPG-managed `-rw` Services. This image contains SQL support only; it does not run replication clients inside PostgreSQL.

## Package and runtime details

PG18 images use the PGDG `postgresql-18-londiste-sql` package. Its full Debian copyright notice is carried in `/licenses/postgresql-18-londiste-sql/`; `/licenses/runtime-packages.tsv` lists the exact package versions and architectures used to supply this payload. Requires the `pgq-node` image/database extension (which in turn requires `pgq`). The external Londiste client and PGQ daemon are not included.

The image supports PostgreSQL 18 on Debian Bookworm and Trixie. Renovate tracks the PGDG package pins in `metadata.hcl`.
