# Perl-compatible regular expressions

<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

pgpcre adds a PCRE2-backed regular-expression type and capture functions to PostgreSQL. See the [upstream project](https://github.com/petere/pgpcre) for the extension documentation.

This image supports PostgreSQL 18 on Debian Bookworm and Trixie. The selected PGDG package versions are maintained independently per suite in `metadata.hcl`.

## Install with CloudNativePG

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pgpcre
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: pgpcre
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pgpcre
        reference: ghcr.io/cnpg-extensions/pgpcre:0.20190509-18-trixie
      ld_library_path: [system]
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pgpcre-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pgpcre
  extensions:
  - name: pgpcre
    # The SQL catalog version is fixed at 1; the PGDG package release is date-based.
    version: '1'
```

The PGDG package links to PCRE2 10.42 on Bookworm and 10.46 on Trixie. The build stages the resolved runtime library and its Debian copyright notice.

### SQL example

```sql
SELECT pcre_match('^([A-Z]+)-([0-9]+)$'::pcre, 'DB-42');
```


## Licenses and updates

The extension is licensed under `PostgreSQL`. The image bundles the extension and linked runtime package copyright files, complete Debian common license texts, the exact runtime package names, versions, and architecture inventory in `/licenses/runtime-packages.txt`, and applicable copyleft source package versions in `/licenses/source-packages.txt` with source archives under `/source`. Renovate tracks the suite-specific PGDG package; rebuilding against the supported Debian suite refreshes package dependencies, linked libraries, their notices, and required source artifacts. Review package and runtime dependency changes when updating the image.
