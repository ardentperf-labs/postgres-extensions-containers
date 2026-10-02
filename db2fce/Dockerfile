# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# The CNPG base image supplies PostgreSQL and the system runtime libraries.
RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-db2fce=${EXT_VERSION}"

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-db2fce/copyright /licenses/postgresql-${PG_MAJOR}-db2fce/

# Libraries
# This SQL-only extension has no shared objects.

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/db2fce* /share/extension/

USER 65532:65532
