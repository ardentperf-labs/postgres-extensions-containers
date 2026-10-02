# Bucardo server schema
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

The PGDG Bucardo server schema and its PL/PerlU routines for asynchronous, trigger-based replication. The packaged schema is source SQL at [`bucardo.schema`](bucardo.schema); the Bucardo daemon remains an external process. [Upstream project](https://bucardo.org/).

## Usage

### Server image

The PL/Perl image provides both server languages, DBI, DBD::Pg and the native
runtime dependencies. Create the control database and replication databases
declaratively, then run the schema from the Bucardo image with a one-shot
`psql` Job. The Job below mounts the image payload read-only; it does not copy
SQL into a ConfigMap or require shell access to a PostgreSQL pod.

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-bucardo
spec:
  imageCatalogRef:
    apiGroup: postgresql.cnpg.io
    kind: ClusterImageCatalog
    name: postgresql-minimal-trixie
    major: 18
  enableSuperuserAccess: true
  instances: 1
  storage:
    size: 1Gi
  managed:
    roles:
    - name: bucardo
      ensure: present
      login: true
      superuser: true
  postgresql:
    extensions:
    - name: plperl
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-plperl-18
        reference: ghcr.io/cnpg-extensions/plperl:18.6-18-trixie
      env:
      - name: PERL5LIB
        value: ${image_root}/perl/arch:${image_root}/perl/share:${image_root}/perl/vendor-arch:${image_root}/perl/vendor-share
    - name: bucardo
      image:
        # renovate: suite=trixie-pgdg depName=bucardo
        reference: ghcr.io/cnpg-extensions/bucardo:5.6.0-18-trixie
~~~

Declare the control database and PL/Perl languages before running the installer:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-bucardo-control
spec:
  name: bucardo
  owner: bucardo
  cluster:
    name: cluster-bucardo
  extensions:
  - name: plperl
    version: '1.0'
  - name: plperlu
    version: '1.0'
~~~

Declare the source and target databases on the same Cluster:

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-bucardo-source
spec:
  name: source_data
  owner: postgres
  cluster:
    name: cluster-bucardo
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-bucardo-target
spec:
  name: target_data
  owner: postgres
  cluster:
    name: cluster-bucardo
~~~

Run a one-shot installer Job after all three Database resources report
`status.applied: true`:

~~~yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: bucardo-schema
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: install
        image: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
        env:
        - name: PGHOST
          value: cluster-bucardo-rw
        - name: PGPORT
          value: '5432'
        - name: PGDATABASE
          value: postgres
        - name: PGUSER
          value: postgres
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: cluster-bucardo-superuser
              key: password
        - name: PGSSLMODE
          value: require
        command:
        - psql
        - -X
        - -v
        - ON_ERROR_STOP=1
        - -f
        - /bucardo/share/extension/bucardo.schema
        volumeMounts:
        - name: bucardo-payload
          mountPath: /bucardo
          readOnly: true
      volumes:
      - name: bucardo-payload
        image:
          reference: ghcr.io/cnpg-extensions/bucardo:5.6.0-18-trixie
          pullPolicy: Always
~~~

The installer uses Kubernetes image volumes (available from Kubernetes 1.33
with the ImageVolume feature enabled). The extension's payload file is mounted
read-only at `/bucardo/share/extension/bucardo.schema` and executed by the
external `psql` client.

Run the compatible `bucardo` daemon as a separate process or container, and
configure its source and target connections to the managed
`cluster-bucardo-rw` Service. Keep passwords in Kubernetes Secrets. The server
schema contains PL/PerlU code and creates a superuser role; reserve it for
trusted administrators. Do not run the daemon inside a PostgreSQL pod. Verify
actual row changes on both databases before declaring the sync healthy.

## Package and runtime details

PG18 images use the PGDG `bucardo` package. Its full Debian copyright notice is carried in `/licenses/bucardo/`. `plperl` runtime image; upstream SQL uses Perl DBI and DBD::Pg. The external daemon is not included in this server image.

The image supports PostgreSQL 18 on Debian Bookworm and Trixie. Renovate tracks the PGDG package pins in `metadata.hcl`.
