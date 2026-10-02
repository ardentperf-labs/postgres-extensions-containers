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
      ld_library_path: []
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

The PGDG package links to PCRE2 10.42 on Bookworm and 10.46 on Trixie. The supported CNPG base images provide these runtime libraries, so the extension adds no files under `/system`.

### SQL example

```sql
SELECT pcre_match('^([A-Z]+)-([0-9]+)$'::pcre, 'DB-42');
```


## Licenses and updates

The extension is licensed under `PostgreSQL`. Its copyright notice is included under `/licenses/<package>/`. The supported CNPG base images provide the runtime libraries required by the extension, so no files are staged under `/system`. The image includes no source archives. Renovate tracks the suite-specific PGDG package; rebuild against the supported Debian suite and review package and notice changes.
