# set_user

PostgreSQL privilege escalation with enhanced logging and control. [Upstream documentation](https://github.com/pgaudit/set_user).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.
Package and runtime validation results are recorded in [evidence](evidence.md).

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-set-user
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    shared_preload_libraries: ["set_user"]
    extensions:
    - name: set-user
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-set-user
        reference: ghcr.io/cnpg-extensions/set-user:4.2.0-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-set-user-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-set-user
  extensions:
  - name: set_user
    version: "4.2.0"
```

## Operation and privileges

Role switching is audited through normal PostgreSQL logging. Restrict EXECUTE on elevation functions and configure allowed roles. Logs follow the CNPG logging pipeline; retain and rotate them in the cluster logging backend. This image does not create separate log files.

## Verify behavior

The [functional SQL fixture](test/functional.sql) shows the supported behavior and
assertions. The Chainsaw test provisions its own Cluster and Database, connects
through the CNPG read/write Service, and checks the SQL result.

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Full installed build-package versions are included in `/licenses/build-packages.tsv`.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture and repeat both distro tests. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

PostgreSQL. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf). See [evidence](evidence.md) for package provenance and validation limits.

The PGDG copyright labels its notice(s) `PostgreSQL and Crunchy`. The permission and
disclaimer text matches the [SPDX PostgreSQL license template](https://github.com/spdx/license-list-data/blob/main/json/details/PostgreSQL.json),
which allows copyright-holder substitutions in the disclaimer paragraphs.
The metadata uses that SPDX identifier; the image retains the complete original
package copyright, including every named holder and notice.
