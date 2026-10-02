# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-pgtap=${EXT_VERSION}"

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-pgtap/copyright /licenses/postgresql-${PG_MAJOR}-pgtap/

# Libraries
# pgTAP is a SQL-only extension and installs no shared library.

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/pgtap* /share/extension/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/uninstall_pgtap.sql /share/extension/

USER 65532:65532
