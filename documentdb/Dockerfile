# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder
ARG PG_MAJOR
ARG EXT_VERSION
USER 0

# Capture base image libraries before installing extension packages.
COPY scripts/capture_base_image_libs.sh /usr/local/bin/capture_base_image_libs.sh
RUN /usr/local/bin/capture_base_image_libs.sh

# Install extension via `apt-get`
RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-documentdb=${EXT_VERSION}"

# Gather system libraries and their licenses
COPY scripts/stage_system_libs.sh /usr/local/bin/stage_system_libs.sh
RUN /usr/local/bin/stage_system_libs.sh /usr/lib/postgresql/${PG_MAJOR}/lib/pg_documentdb.so /usr/lib/postgresql/${PG_MAJOR}/lib/pg_documentdb_core.so /usr/lib/postgresql/${PG_MAJOR}/lib/pg_documentdb_extended_rum*.so

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses /licenses/
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-documentdb/copyright /licenses/postgresql-${PG_MAJOR}-documentdb/

# Libraries
# Citus/distributed artifacts are omitted.
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/pg_documentdb.so /usr/lib/postgresql/${PG_MAJOR}/lib/pg_documentdb_core.so /usr/lib/postgresql/${PG_MAJOR}/lib/pg_documentdb_extended_rum*.so /lib/
# PGDG installs unrelated and distributed bitcode too; include only shipped components.
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb/ /lib/bitcode/pg_documentdb/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb.index.bc /lib/bitcode/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_core/ /lib/bitcode/pg_documentdb_core/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_core.index.bc /lib/bitcode/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_extended_rum/ /lib/bitcode/pg_documentdb_extended_rum/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_extended_rum.index.bc /lib/bitcode/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_extended_rum_core/ /lib/bitcode/pg_documentdb_extended_rum_core/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_extended_rum_core.index.bc /lib/bitcode/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_extended_rum_core_builtin_rmgr/ /lib/bitcode/pg_documentdb_extended_rum_core_builtin_rmgr/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/pg_documentdb_extended_rum_core_builtin_rmgr.index.bc /lib/bitcode/

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/documentdb.control /usr/share/postgresql/${PG_MAJOR}/extension/documentdb--*.sql /share/extension/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/documentdb_core.control /usr/share/postgresql/${PG_MAJOR}/extension/documentdb_core--*.sql /share/extension/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/documentdb_extended_rum.control /usr/share/postgresql/${PG_MAJOR}/extension/documentdb_extended_rum--*.sql /share/extension/

# System libs
COPY --from=builder /system /system/

USER 65532:65532
