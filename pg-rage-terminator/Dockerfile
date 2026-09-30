# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      "pg-rage-terminator-18=${EXT_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

RUN dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' pg-rage-terminator-18 libc6 | sort > /tmp/runtime-packages.tsv

FROM scratch
ARG PG_MAJOR

COPY --from=builder /usr/share/doc/pg-rage-terminator-18/copyright /licenses/pg-rage-terminator-18/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/pg_rage_terminator.so /lib/

COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv

USER 65532:65532
