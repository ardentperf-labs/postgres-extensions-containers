# HTTP requests from PostgreSQL

<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

http adds HTTP client functions to PostgreSQL so SQL can call HTTP services through libcurl. See the [upstream project](https://github.com/pramsey/pgsql-http) for the extension documentation.

This image supports PostgreSQL 18 on Debian Bookworm and Trixie. The selected PGDG package versions are maintained independently per suite in `metadata.hcl`.

## Install with CloudNativePG

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-http
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: http
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-http
        reference: ghcr.io/cnpg-extensions/http:1.7.2-18-trixie
      ld_library_path: [system]
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-http-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-http
  extensions:
  - name: http
    # renovate: suite=trixie-pgdg depName=postgresql-18-http extractVersion=^(?<version>\d+\.\d+)
    version: '1.7'
```

The PGDG package links to libcurl. The build stages the resolved non-core shared libraries and matching Debian copyright notices under `/system` and `/licenses`; no HTTP client daemon is included.

### SQL example

```sql
SELECT status, content FROM http_get('https://example.org/');
```


## Licenses and updates

The extension is licensed under `MIT`. The image bundles the extension and linked runtime package copyright files, complete Debian common license texts, the exact runtime package names, versions, and architecture inventory in `/licenses/runtime-packages.txt`, and applicable copyleft source package versions in `/licenses/source-packages.txt` with source archives under `/source`. Renovate tracks the suite-specific PGDG package; rebuilding against the supported Debian suite refreshes package dependencies, linked libraries, their notices, and required source artifacts. Review package and runtime dependency changes when updating the image.
