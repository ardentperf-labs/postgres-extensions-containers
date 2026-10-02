# PL/Java
<!--
SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
SPDX-License-Identifier: Apache-2.0
-->

PL/Java embeds a Java runtime in PostgreSQL and lets you define Java-backed functions, procedures, triggers, and types. It is PGDG PL/Java 1.6.10 with policy enforcement enabled: Bookworm uses OpenJDK 17, and Trixie uses OpenJDK 21. Both are LTS runtimes supported by this PL/Java release. See the [PL/Java documentation](https://tada.github.io/pljava/) and [security policy guide](https://tada.github.io/pljava/use/policy.html).

## Use with CloudNativePG

Mount the image into a PostgreSQL 18 cluster:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-pljava
spec:
  imageCatalogRef:
    apiGroup: postgresql.cnpg.io
    kind: ClusterImageCatalog
    name: postgresql-minimal-trixie
    major: 18
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    parameters:
      pljava.libjvm_location: /extensions/pljava/jvm/lib/server/libjvm.so
      pljava.module_path: /extensions/pljava/share/pljava/pljava-1.6.10.jar:/extensions/pljava/share/pljava/pljava-api-1.6.10.jar
      pljava.vmoptions: "-Djava.security.manager=allow -Djava.io.tmpdir=/controller/tmp"
      pljava.policy_urls: '"file:/extensions/pljava/share/pljava.policy"'
    extensions:
    - name: pljava
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-pljava
        reference: ghcr.io/cnpg-extensions/pljava:1.6.10-18-trixie
      ld_library_path:
      - jvm/lib/server
      - jvm/lib
      - system
```

Enable PL/Java in a database with a `Database` resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-pljava-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-pljava
  extensions:
  - ensure: present
    name: pljava
    # renovate: suite=trixie-pgdg depName=postgresql-18-pljava extractVersion=^(?<version>\d+\.\d+\.\d+)
    version: '1.6.10'
```

The cluster must set the four PL/Java GUCs to paths under CNPG's `/extensions/pljava` mount, as shown above. The extension image adds `jvm/lib/server`, `jvm/lib`, and `system` to the loader path; `/system` contains Java native dependencies missing from the CNPG base image. A basic arithmetic function can verify it:

```sql
CREATE FUNCTION java_add(integer, integer) RETURNS integer
AS 'java.lang.Integer.sum' LANGUAGE java;
SELECT java_add(19, 23); -- 42
```

PL/Java creates the trusted `java` language and untrusted `javaU` language. `java` functions may be created by roles granted `USAGE` on the language; only superusers may create `javaU` functions. The included default policy grants sandboxed `java` code no extra permissions and grants `javaU` filesystem read/write/delete permissions, still limited by the PostgreSQL operating-system user's permissions. Grant only the database privileges application roles need. The selected Java 17/21 versions support policy enforcement; Java 24 and later do not support PL/Java 1.6.10 policy enforcement. The included example does not create persistent files. `javaU` can write files allowed by the PL/Java policy and the PostgreSQL operating-system account. The Cluster example directs JVM temporary files to CNPG's ephemeral scratch mount at `/controller/tmp`; those files share the pod's lifecycle and disappear when the pod is replaced. For application files that must persist, declare a volume with suitable ownership/access, retention, and cleanup before enabling file-producing functions.

## Package and dependency notes

The image includes the PL/Java native module, SQL/control files, both PL/Java JARs, the complete OpenJDK runtime selected by Debian's `default-jre` package, and the PGDG default policy. The OpenJDK runtime is under `/jvm`; the example uses CNPG's `/extensions/pljava` mount path. System libraries absent from the matching CNPG base are placed under `/system`. Package copyright notices are under `/licenses`.

Renovate tracks the PGDG `postgresql-18-pljava` package. The Debian base suite selects OpenJDK 17 or 21; rebuild after either package changes. The Dagger runner installs PL/Java and deploys the PGDG-packaged upstream examples JAR from the mounted image, exercising its deployment descriptor against the installed module and JVM; see [test/UPSTREAM](test/UPSTREAM) and [test/run.sh](test/run.sh). The vendored Maven/JUnit source tests are retained for provenance but are not run because they rebuild PL/Java.

## Contributors

Maintained by [@ardentperf](https://github.com/ardentperf).
