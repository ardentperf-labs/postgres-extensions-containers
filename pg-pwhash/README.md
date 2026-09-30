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

The PGDG package links to libscrypt, libargon2, libxcrypt, and OpenSSL. The linked libxcrypt runtime is LGPL-licensed; the exact `libxcrypt` source package is bundled under `/source`. The package copyright files and exact runtime package versions are recorded with the rest of the runtime closure.

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

The extension is licensed under `MIT`. The image bundles the extension and linked runtime package copyright files, complete Debian common license texts, the exact runtime package names, versions, and architecture inventory in `/licenses/runtime-packages.txt`, and applicable copyleft source package versions in `/licenses/source-packages.txt` with source archives under `/source`. Renovate tracks the suite-specific PGDG package; rebuilding against the supported Debian suite refreshes package dependencies, linked libraries, their notices, and required source artifacts. Review package and runtime dependency changes when updating the image.
