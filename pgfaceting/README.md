# pgfaceting

Faceted query acceleration for PostgreSQL using roaring bitmaps. [Upstream documentation](https://github.com/cybertec-postgresql/pgfaceting).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgfaceting
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pgfaceting
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgfaceting
        reference: ghcr.io/cnpg-extensions/pgfaceting:0.2.0-18-trixie
    - name: roaringbitmap
      image:
        reference: ghcr.io/cnpg-extensions/roaringbitmap:1.2.0-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pgfaceting-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pgfaceting
  extensions:
  - name: roaringbitmap
  - name: pgfaceting
    version: "0.2.0"
```

## Operation and privileges

Mount the matching roaringbitmap image and create `roaringbitmap` before `pgfaceting`. Facet indexes and pending deltas are database tables. Schedule `faceting.merge_deltas()` through a SQL scheduler; normal PostgreSQL privileges and data-volume retention apply.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Full installed build-package versions are included in `/licenses/build-packages.tsv`.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture and repeat both distro tests. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

BSD-3-Clause. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
