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

RUN set -eu; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "postgresql-plpython3-${PG_MAJOR}=${EXT_VERSION}" python3

# Gather system libraries and their licenses
COPY scripts/stage_system_libs.sh /usr/local/bin/stage_system_libs.sh

RUN set -eu; \
    /usr/local/bin/stage_system_libs.sh \
      "/usr/lib/postgresql/${PG_MAJOR}/lib/plpython3.so" \
      "/usr/lib/postgresql/${PG_MAJOR}/lib/hstore_plpython3.so" \
      "/usr/lib/postgresql/${PG_MAJOR}/lib/jsonb_plpython3.so" \
      "/usr/lib/postgresql/${PG_MAJOR}/lib/ltree_plpython3.so" \
      /usr/lib/*-linux-gnu/libpython3.*.so.1.0 \
      /usr/lib/python3.*/lib-dynload/*.so

# Dereference runtime symlinks before copying into the final image.
RUN mkdir -p /tmp/python/lib && \
    cp -aL "$(python3 -c 'import sysconfig; print(sysconfig.get_path("stdlib"))')" /tmp/python/lib/

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses /licenses/
COPY --from=builder /usr/share/doc/python3/copyright /licenses/python3/copyright
COPY --from=builder /usr/share/doc/python3.*/copyright /licenses/python-runtime/copyright
COPY --from=builder /usr/share/doc/postgresql-plpython3-${PG_MAJOR}/copyright /licenses/postgresql-plpython3-${PG_MAJOR}/copyright

# Libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/*plpython3*.so /lib/

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/*plpython3* /share/extension/

# Runtime
COPY --from=builder /tmp/python/ /python/

# System libs
COPY --from=builder /system /system/

USER 65532:65532
