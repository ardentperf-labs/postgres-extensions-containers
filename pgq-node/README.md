# pgq_node
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

Cascaded queueing support SQL layered on PgQ. [Upstream project](https://github.com/pgq/pgq-node).

## Usage

Declare both server images so `pgq_node` can use PgQ, then install both extensions in the Database:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgq-node
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
~~~

Install both database extensions:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pgq-node-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pgq-node
  extensions:
  - name: pgq
    version: '3.5.1'
  - name: pgq_node
    # renovate: suite=trixie-pgdg depName=postgresql-18-pgq-node extractVersion=^(?<version>\d+\.\d+)
    version: '3.5'
~~~

Use the upstream `pgq_node` client to register nodes and routes. Keep those clients outside the managed PostgreSQL container.

## Package and runtime details

PG18 images use the PGDG `postgresql-18-pgq-node` package. Its full Debian copyright notice is carried in `/licenses/postgresql-18-pgq-node/`; `/licenses/runtime-packages.tsv` lists the exact package versions and architectures used to supply this payload. Requires this repository’s `pgq` server image and database extension. Client/daemon utilities are separate processes.

The image supports PostgreSQL 18 on Debian Bookworm and Trixie. Renovate tracks the PGDG package pins in `metadata.hcl`.
