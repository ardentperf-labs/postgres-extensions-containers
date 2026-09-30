# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-pgq3=${EXT_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

RUN dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' postgresql-18-pgq3 libc6 libpq5 | sort > /tmp/runtime-packages.tsv

FROM scratch
ARG PG_MAJOR

COPY --from=builder /usr/share/doc/postgresql-18-pgq3/copyright /licenses/postgresql-18-pgq3/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/pgq_*.so /lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/pgq* /share/extension/

COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv

USER 65532:65532
