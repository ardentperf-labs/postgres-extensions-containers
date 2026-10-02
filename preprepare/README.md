# preprepare

pre prepare your PostgreSQL statements server side. [Upstream documentation](https://apt.postgresql.org/pub/repos/apt/).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-preprepare
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: preprepare
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-preprepare
        reference: ghcr.io/cnpg-extensions/preprepare:0.9-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-preprepare-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-preprepare
  extensions:
  - name: pre_prepare
    version: "0.4"
```

## Operation and privileges

This image provides SQL extension `pre_prepare`. Prepared statements and their source table are session-local; no files are needed. Use `prepare_all('schema.table')` to load statement definitions from an administrator-controlled table of complete PREPARE statements. Restrict which users can modify the source table.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

PostgreSQL. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).

The PGDG copyright labels its notice(s) `BSD`. The permission and
disclaimer text matches the [SPDX PostgreSQL license template](https://github.com/spdx/license-list-data/blob/main/json/details/PostgreSQL.json),
which allows copyright-holder substitutions in the disclaimer paragraphs.
The metadata uses that SPDX identifier; the image retains the complete original
package copyright, including every named holder and notice.
