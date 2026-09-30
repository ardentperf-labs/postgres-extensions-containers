# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-decoderbufs=${EXT_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

RUN dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' postgresql-${PG_MAJOR}-decoderbufs libprotobuf-c1 libc6 | sort > /tmp/runtime-packages.tsv

FROM scratch
ARG PG_MAJOR

COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-decoderbufs/copyright /licenses/postgresql-${PG_MAJOR}-decoderbufs/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/decoderbufs.so /lib/
COPY --from=builder /usr/lib/*/libprotobuf-c.so.1* /system/
COPY --from=builder /usr/share/doc/libprotobuf-c1/copyright /licenses/libprotobuf-c1/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/decoderbufs.control /share/extension/

COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv

USER 65532:65532
