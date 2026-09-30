# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-powa=${EXT_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    module="/usr/lib/postgresql/${PG_MAJOR}/lib/powa.so"; \
    test -s "$module"; \
    ldd "$module" > /tmp/powa-ldd.txt; \
    if grep -q 'not found' /tmp/powa-ldd.txt; then cat /tmp/powa-ldd.txt >&2; exit 1; fi; \
    dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' \
      "postgresql-${PG_MAJOR}-powa" "postgresql-${PG_MAJOR}" libc6 | sort > /tmp/runtime-packages.tsv

FROM scratch
ARG PG_MAJOR

COPY --from=builder /usr/share/doc/postgresql-18-powa/copyright /licenses/postgresql-18-powa/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/powa.so /lib/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/powa/ /lib/bitcode/powa/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/powa.index.bc /lib/bitcode/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/powa* /share/extension/

COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv

USER 65532:65532
