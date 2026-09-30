# roaringbitmap
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

Provides compressed Roaring bitmap data structures and set operations for PostgreSQL. See the [upstream project](https://github.com/ChenHuajun/pg_roaringbitmap) for its API and release history.

## Use with CloudNativePG

Add this image to a PostgreSQL 18 Cluster on Trixie. Choose the Bookworm image tag when the base image uses Bookworm.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-roaringbitmap
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
    - name: roaringbitmap
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-roaringbitmap
        reference: ghcr.io/cnpg-extensions/roaringbitmap:1.2.0-18-trixie
```

Install the SQL extension in a database with a CNPG `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-roaringbitmap-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-roaringbitmap
  extensions:
  - ensure: present
    name: roaringbitmap
    version: "1.2"
```

A SQL check that exercises the installed extension is:

```sql
SELECT rb_cardinality(rb_build(ARRAY[1,2,3])) = 3;
```

## Package, dependencies and maintenance

The image installs PGDG package `postgresql-18-roaringbitmap` at the Debian version recorded in `metadata.hcl`. Each image includes `/licenses/runtime-packages.tsv` with the exact extension and runtime package/source versions for that build. Package updates are tracked by Renovate; review changes against the package's control file and rerun the target's build and Chainsaw tests. The package is available for PostgreSQL 18 on both Bookworm and Trixie, amd64 and arm64. It depends on the CNPG PostgreSQL 18 base image and libc; no additional runtime package is installed. The roaringbitmap module uses Apache-2.0 licensing. Its Debian copyright file and full license text are included under `/licenses/`; the exact PGDG source archives, including the upstream tarball and Debian packaging, are included under `/source/` for corresponding source and reproducible rebuilds. The source archives include the vendored CRoaring 4.3.11 source (Apache-2.0), statically compiled into the extension; its version is recorded in `include/roaring/roaring_version.h`.

