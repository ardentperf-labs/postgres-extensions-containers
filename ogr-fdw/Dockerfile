# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# Capture base image libraries before installing the extension package.
COPY scripts/capture_base_image_libs.sh /usr/local/bin/capture_base_image_libs.sh
RUN /usr/local/bin/capture_base_image_libs.sh

# Install extension via `apt-get`
RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-ogr-fdw=${EXT_VERSION}"

# Gather system libraries and their licenses
COPY scripts/stage_system_libs.sh /usr/local/bin/stage_system_libs.sh
RUN /usr/local/bin/stage_system_libs.sh "/usr/lib/postgresql/${PG_MAJOR}/lib/ogr_fdw.so"

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses /licenses/
COPY --from=builder /usr/share/doc/gdal-data/copyright /licenses/gdal-data/copyright
COPY --from=builder /usr/share/doc/proj-data/copyright /licenses/proj-data/copyright
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-ogr-fdw/copyright /licenses/postgresql-${PG_MAJOR}-ogr-fdw/copyright

# Libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/ogr_fdw.so /lib/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/ /lib/bitcode/

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/ogr_fdw.control /usr/share/postgresql/${PG_MAJOR}/extension/ogr_fdw--*.sql /share/extension/
COPY --from=builder /usr/share/gdal/ /share/gdal/
COPY --from=builder /usr/share/proj/ /share/proj/

# System libs
COPY --from=builder /system /system/

USER 65532:65532
