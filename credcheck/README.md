# credcheck

PostgreSQL username/password checks. [Upstream documentation](https://github.com/MigOpsRepos/credcheck).

## Supported images

PostgreSQL 18; Debian Trixie and Bookworm; amd64 and arm64 build targets.
Package and runtime validation results are recorded in [evidence](evidence.md).

## Declarative setup

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-credcheck
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    parameters:
      credcheck.encrypted_password_allowed: "on"
    shared_preload_libraries: ["credcheck"]
    extensions:
    - name: credcheck
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-credcheck
        reference: ghcr.io/cnpg-extensions/credcheck:5.0-18-trixie
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-credcheck-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-credcheck
  extensions:
  - name: credcheck
    version: "5.0.0"
```

## Operation and privileges

CNPG reconciles role credentials using precomputed SCRAM verifiers. Set `credcheck.encrypted_password_allowed: "on"` so those updates succeed. Plaintext password policy cannot inspect precomputed verifiers; enforce equivalent policy where Kubernetes password Secrets are generated. SQL role changes using plaintext passwords remain checked.

Credential checks apply to role creation and password changes. Configure policy settings in `postgresql.parameters`; only administrators should change them. The test enforces a minimum plaintext password length and proves that a weak password is rejected.

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

MIT. Redistribution notices are preserved under `/licenses/`.
Maintained by Jeremy Schneider (@ardentperf). See [evidence](evidence.md) for package provenance and validation limits.
