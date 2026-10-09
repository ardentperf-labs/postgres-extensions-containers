# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# The CNPG base image supplies PostgreSQL and the system runtime libraries.
RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-roaringbitmap=${EXT_VERSION}"

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-roaringbitmap/copyright /licenses/postgresql-${PG_MAJOR}-roaringbitmap/

# Libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/roaringbitmap* /lib/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/ /lib/bitcode/

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/roaringbitmap* /share/extension/

USER 65532:65532
