# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder
ARG PG_MAJOR
ARG EXT_VERSION
USER 0
# Use the suite-matching interpreter to stage its own standard library.
RUN apt-get update && apt-get install -y --no-install-recommends \
    "postgresql-plpython3-${PG_MAJOR}=${EXT_VERSION}" python3
# Enable matching source indexes to redistribute exact dependency source packages.
RUN set -eu; \
    for file in /etc/apt/sources.list.d/*.sources; do \
      test ! -f "$file" || sed -i 's/^Types: deb$/Types: deb deb-src/' "$file"; \
    done; \
    . /etc/os-release; \
    printf 'deb-src [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$VERSION_CODENAME" > /etc/apt/sources.list.d/plpython3-source.list; \
    apt-get update
COPY plpython3/stage.py /stage.py
RUN python3 /stage.py
FROM scratch
COPY --from=builder /out/ /
USER 65532:65532
