# Advanced password hashing

<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

pg_pwhash provides adaptive Argon2, scrypt, and yescrypt password-hashing functions backed by packaged cryptographic libraries. See the [upstream project](https://github.com/cybertec-postgresql/pg_pwhash) for the extension documentation.

This image supports PostgreSQL 18 on Debian Bookworm and Trixie. The selected PGDG package versions are maintained independently per suite in `metadata.hcl`.

## Install with CloudNativePG

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pg-pwhash
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pg-pwhash
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pg-pwhash
        reference: ghcr.io/cnpg-extensions/pg-pwhash:1.0-18-trixie
      ld_library_path: [system]
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pg-pwhash-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pg-pwhash
  extensions:
  - name: pg_pwhash
    # renovate: suite=trixie-pgdg depName=postgresql-18-pg-pwhash extractVersion=^(?<version>\d+\.\d+)
    version: '1.0'
```

The PGDG package uses libscrypt, libargon2, libxcrypt, and OpenSSL. Its runtime dependencies are provided by the CNPG base image or staged under `/system`, with copyright notices for bundled runtime packages under `/licenses/<package>/`. The image includes no source archives.

Choose hash parameters that meet your application security and latency requirements; the upstream documentation explains supported algorithms and tuning options.

### SQL example

```sql
SELECT pwhash_crypt('password', pwhash_gen_salt('argon2id'));
```

As with PostgreSQL's `crypt()`, verify a candidate password by passing the stored hash as the salt argument:

```sql
SELECT pwhash_crypt('candidate-password', stored_hash) = stored_hash;
```


## Licenses and updates

The extension is licensed under `MIT`. Its copyright notice and notices for bundled runtime packages are included under `/licenses/<package>/`. The image includes no source archives. Renovate tracks the suite-specific PGDG package; rebuild against the supported Debian suite to refresh runtime files and review dependency and notice changes.
