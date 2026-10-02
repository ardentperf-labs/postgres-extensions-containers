# prioritize

Get and set the nice priorities of PostgreSQL backends. [Upstream documentation](http://pgxn.org/dist/prioritize/).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-prioritize
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: prioritize
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-prioritize
        reference: ghcr.io/cnpg-extensions/prioritize:1.0.4-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-prioritize-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-prioritize
  extensions:
  - name: prioritize
    version: "1.0"
```

## Operation and privileges

Backend priority functions require database privileges and are subject to OS permissions. An unprivileged CNPG process can lower its scheduling priority by increasing the nice value; raising priority normally requires CAP_SYS_NICE and is not supported. No extra capability is requested. The test changes only its own disposable backend.

## Verify behavior

The vendored upstream suite is pinned in [test/UPSTREAM](test/UPSTREAM) and
invoked by [test/run.sh](test/run.sh).

## Dependencies and updates

The image contains only the PGDG package server payload and license notices.
The matching CNPG minimal image supplies PostgreSQL, libc and its base runtime.
Renovate tracks the pinned extension package. For an extension or base-runtime
security fix, update the affected package/base image, rebuild every advertised
architecture and rerun both distro regression suites. SQL versions must be checked against
the installed control file separately because they need not match package versions.

## Licenses and ownership

PostgreSQL. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf).
