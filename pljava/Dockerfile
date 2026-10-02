# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder
ARG PG_MAJOR
ARG EXT_VERSION
ARG TARGETARCH
USER 0

# Capture base image libraries before installing extension packages.
COPY scripts/capture_base_image_libs.sh /usr/local/bin/capture_base_image_libs.sh
RUN /usr/local/bin/capture_base_image_libs.sh

RUN set -eu; \
    . /etc/os-release; \
    case "$VERSION_CODENAME" in \
      bookworm) java_version=17; jre_package=openjdk-17-jre-headless; runtime_packages='libasound2 libbrotli1 libfreetype6 libglib2.0-0 libgraphite2-3 libharfbuzz0b libjpeg62-turbo liblcms2-2 libpcre2-8-0 libpcsclite1 libpng16-16 libstdc++6 zlib1g' ;; \
      trixie) java_version=21; jre_package=openjdk-21-jre-headless; runtime_packages='libasound2t64 libatomic1 libbrotli1 libbz2-1.0 libfreetype6 libgcc-s1 libglib2.0-0t64 libgraphite2-3 libharfbuzz0b libjpeg62-turbo liblcms2-2 libpcre2-8-0 libpcsclite1 libpng16-16t64 libstdc++6 zlib1g' ;; \
      *) echo "unsupported Debian suite: $VERSION_CODENAME" >&2; exit 1 ;; \
    esac; \
    case "$TARGETARCH" in amd64|arm64) java_arch="$TARGETARCH" ;; *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; esac; \
    apt-get update; \
    apt-get install -y --no-install-recommends "postgresql-${PG_MAJOR}-pljava=${EXT_VERSION}" "$jre_package" $runtime_packages; \
    jre_home="/usr/lib/jvm/java-${java_version}-openjdk-${java_arch}"; \
    test -s "$jre_home/lib/server/libjvm.so"; \
    for library in "$jre_home"/lib/*.so "$jre_home"/lib/server/*.so; do \
      [ -e "$library" ] || continue; \
      printf '%s\n' "$library" "$(readlink -f "$library")" >> /tmp/base-image-libs.out; \
    done; \
    sort -u /tmp/base-image-libs.out -o /tmp/base-image-libs.out; \
    mkdir -p /tmp/jvm "/licenses/${jre_package}"; \
    cp -aL "$jre_home/." /tmp/jvm/; \
    cp "/usr/share/doc/${jre_package}/copyright" "/licenses/${jre_package}/copyright"; \
    printf '%s\n' "$jre_home" > /tmp/jre-home

# Gather system libraries and their licenses
COPY scripts/stage_system_libs.sh /usr/local/bin/stage_system_libs.sh

RUN set -eu; \
    jre_home=$(cat /tmp/jre-home); \
    export LD_LIBRARY_PATH="$jre_home/lib/server:$jre_home/lib"; \
    bash -c ' \
      set -euo pipefail; \
      shopt -s nullglob; \
      jre_home="$1"; \
      objects=("$(readlink -f "$jre_home/bin/java")"); \
      for library in /usr/lib/postgresql/"${PG_MAJOR}"/lib/libpljava*.so \
        "$jre_home"/lib/*.so "$jre_home"/lib/server/*.so; do \
        objects+=("$(readlink -f "$library")"); \
      done; \
      /usr/local/bin/stage_system_libs.sh "${objects[@]}" \
    ' bash "$jre_home"

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses /licenses/
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
