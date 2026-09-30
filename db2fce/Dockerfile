# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# The CNPG base image supplies PostgreSQL and the system runtime libraries.
RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-db2fce=${EXT_VERSION}" \
    && rm -rf /var/lib/apt/lists/*


# Record the installed SQL-only extension and PostgreSQL server package versions.
RUN set -eu; \
    runtime_packages="postgresql-${PG_MAJOR}-db2fce postgresql-${PG_MAJOR}"; \
    { \
      printf '# binary-package\tversion\tsource-package\tsource-version\n'; \
      for package in $(printf '%s\n' "$runtime_packages" | tr ' ' '\n' | sed '/^$/d' | sort -u); do \
        dpkg-query -W -f='${binary:Package}\t${Version}\t${source:Package}\t${source:Version}\n' "$package"; \
      done; \
    } | awk 'NR == 1 { print; next } !seen[$0]++' > /tmp/runtime-packages.tsv

FROM scratch
ARG PG_MAJOR

# Debian copyright file includes upstream attribution and package license terms.
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-db2fce/copyright /licenses/postgresql-${PG_MAJOR}-db2fce/
COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv

# Extension control file and SQL installation/upgrade scripts.
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/db2fce* /share/extension/

USER 65532:65532
