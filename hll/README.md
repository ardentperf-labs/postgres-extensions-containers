# hll
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

Provides HyperLogLog types and aggregates for approximate distinct-counting. See the [upstream project](https://github.com/citusdata/postgresql-hll) for its API and release history.

## Use with CloudNativePG

Add this image to a PostgreSQL 18 Cluster on Trixie. Choose the Bookworm image tag when the base image uses Bookworm.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-hll
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
    - name: hll
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-hll
        reference: ghcr.io/cnpg-extensions/hll:2.21-18-trixie
```

Install the SQL extension in a database with a CNPG `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-hll-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-hll
  extensions:
  - ensure: present
    name: hll
    version: "2.21"
```

A SQL check that exercises the installed extension is:

```sql
SELECT (SELECT hll_cardinality(hll_add_agg(hll_hash_integer(i))) BETWEEN 95 AND 105 FROM generate_series(1,100) AS s(i));
```

## Package, dependencies and maintenance

The image installs PGDG package `postgresql-18-hll` at the Debian version recorded in `metadata.hcl`. Each image includes `/licenses/runtime-packages.tsv` with the exact extension and runtime package/source versions for that build. Package updates are tracked by Renovate; review changes against the package's control file and rerun the target's build and Chainsaw tests. The package is available for PostgreSQL 18 on both Bookworm and Trixie, amd64 and arm64. It depends on the CNPG PostgreSQL 18 base image and libc; no additional runtime package is installed. The hll module uses Apache-2.0 licensing. Its Debian copyright file and full license text are included under `/licenses/`; the exact PGDG source archives, including the upstream tarball and Debian packaging, are included under `/source/` for corresponding source and reproducible rebuilds. The image also includes the exact PGDG source archives; these document vendored MurmurHash3 source (public domain, no independent version) compiled into the extension.

