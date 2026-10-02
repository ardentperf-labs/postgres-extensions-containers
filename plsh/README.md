# plsh

PL/sh procedural language for PostgreSQL 18. [Upstream documentation](https://github.com/petere/plsh).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-plsh
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: plsh
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-plsh
        reference: ghcr.io/cnpg-extensions/plsh:1.20220917-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-plsh-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-plsh
  extensions:
  - name: plsh
    version: "2"
```

## Operation and privileges

PL/sh is an untrusted language: only superusers can create its functions. Commands run as the PostgreSQL OS user and inherit its filesystem and network access. This image supports the `/bin/sh` already supplied by the matching CNPG minimal image, with shell built-ins only. It does not add arbitrary external commands or support file-producing functions. Restrict function EXECUTE grants to trusted administrators.

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
