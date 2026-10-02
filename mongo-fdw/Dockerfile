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

# Mongo driver compatibility patch
COPY mongo-fdw/patches/mongoc-aggregate-db-order.patch /tmp/mongoc-aggregate-db-order.patch

RUN set -eu; \
    sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/pgdg.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends dpkg-dev "postgresql-${PG_MAJOR}-mongo-fdw=${EXT_VERSION}"; \
    mongo_version="$(dpkg-query -W -f='${source:Version}' libmongoc-1.0-0t64)"; \
    apt-get build-dep -y --no-install-recommends "mongo-c-driver=${mongo_version}"; \
    mkdir -p /tmp/mongo-driver-source /tmp/mongo-driver-patched; \
    cd /tmp/mongo-driver-source; \
    apt-get source "mongo-c-driver=${mongo_version}"; \
    set -- /tmp/mongo-driver-source/mongo-c-driver-*; \
    test -d "$1"; \
    patch -d "$1" -p1 < /tmp/mongoc-aggregate-db-order.patch; \
    cd "$1"; \
    DEB_BUILD_OPTIONS='nocheck nodoc' dpkg-buildpackage -B -uc -us; \
    dpkg-deb -x /tmp/mongo-driver-source/libmongoc-1.0-0t64_*_*.deb /tmp/mongo-driver-patched; \
    cp -L /tmp/mongo-driver-patched/usr/lib/*/libmongoc-1.0.so.0 /tmp/mongoc-patched-libmongoc.so

# Gather system libraries and their licenses
COPY scripts/stage_system_libs.sh /usr/local/bin/stage_system_libs.sh
RUN /usr/local/bin/stage_system_libs.sh \
    "/usr/lib/postgresql/${PG_MAJOR}/lib/mongo_fdw.so" \
    /tmp/mongoc-patched-libmongoc.so

# Replace the driver with the patched build and check its library resolution.
RUN set -eu; \
    rm -f /system/libmongoc-1.0.so*; \
    cp -a /tmp/mongoc-patched-libmongoc.so /system/libmongoc-1.0.so.0; \
    ln -s libmongoc-1.0.so.0 /system/libmongoc-1.0.so; \
    missing="$(LD_LIBRARY_PATH=/system ldd "/usr/lib/postgresql/${PG_MAJOR}/lib/mongo_fdw.so" | grep 'not found' || true)"; \
    if [ -n "$missing" ]; then printf "%s\n" "$missing" >&2; exit 1; fi

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses /licenses/
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-mongo-fdw/copyright /licenses/postgresql-${PG_MAJOR}-mongo-fdw/copyright

# Libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/mongo_fdw.so /lib/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/ /lib/bitcode/

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/mongo_fdw.control /usr/share/postgresql/${PG_MAJOR}/extension/mongo_fdw--*.sql /share/extension/

# System libs
COPY --from=builder /system /system/

USER 65532:65532
