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

RUN apt-get update && apt-get install -y \
    "postgresql-${PG_MAJOR}-pljava=${EXT_VERSION}" default-jre

# Gather system libraries and their licenses
COPY scripts/stage_system_libs.sh /usr/local/bin/stage_system_libs.sh

RUN set -eu; \
    jre_home=/usr/lib/jvm/default-java; \
    export LD_LIBRARY_PATH="$jre_home/lib/server:$jre_home/lib"; \
    /usr/local/bin/stage_system_libs.sh --exclude-dir "$jre_home" \
      "$jre_home/bin/java" \
      /usr/lib/postgresql/"${PG_MAJOR}"/lib/libpljava*.so \
      "$jre_home"/lib/*.so \
      "$jre_home"/lib/server/*.so

# Dereference runtime symlinks before copying into the final image.
RUN mkdir -p /tmp/jvm && \
    cp -aL /usr/lib/jvm/default-java/. /tmp/jvm/

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses /licenses/
COPY --from=builder /usr/share/doc/default-jre/copyright /licenses/default-jre/copyright
COPY --from=builder /usr/share/doc/openjdk-*-jre-headless/copyright /licenses/openjdk-jre/copyright
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-pljava/copyright /licenses/postgresql-${PG_MAJOR}-pljava/copyright

# Libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/libpljava*.so /lib/

# Share
COPY --from=builder /etc/postgresql-common/pljava.policy /share/pljava.policy
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/pljava.control /share/extension/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/pljava/ /share/pljava/

# Runtime
COPY --from=builder /tmp/jvm/ /jvm/

# System libs
COPY --from=builder /system /system/

USER 65532:65532
