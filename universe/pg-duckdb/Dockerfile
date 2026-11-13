# SPDX-License-Identifier: Apache-2.0
ARG BUILDKIT_SBOM_SCAN_STAGE=builder
ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM ${BASE} AS builder
ARG PG_MAJOR=18
ARG EXT_VERSION
ARG SOURCE_REPOSITORY
ARG SOURCE_REVISION
ARG TARGETARCH
USER 0
COPY source-build/ /source-build/
COPY universe/pg-duckdb/acquire.py /recipe/acquire.py
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl git cmake ninja-build python3 pkg-config \
    libssl-dev libcurl4-openssl-dev liblz4-dev libicu-dev postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN python3 /recipe/acquire.py
RUN CMAKE_BUILD_PARALLEL_LEVEL=2 make -j2 DISABLE_UNITY=1 DUCKDB_BUILD=ReleaseStaticSystem PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config PG_DUCKDB_VERSION=${EXT_VERSION} \
    && CMAKE_BUILD_PARALLEL_LEVEL=2 make -j2 DISABLE_UNITY=1 install DESTDIR=/install DUCKDB_BUILD=ReleaseStaticSystem PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config
ARG BUILD_TIMESTAMP
COPY universe/pg-duckdb/evidence.py universe/pg-duckdb/augment_spdx.py /recipe/
RUN python3 /recipe/evidence.py \
    && install -D -m 0644 /recipe/augment_spdx.py /usr/local/share/cnpg-sbom/augment_spdx.py
FROM scratch
COPY --from=builder /payload/ /
USER 65532:65532
