# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder
ARG PG_MAJOR
ARG EXT_VERSION
USER 0
RUN apt-get update && apt-get install -y --no-install-recommends "postgresql-${PG_MAJOR}-prioritize=${EXT_VERSION}"

# Copy only this package's server payload, preserving PostgreSQL-relative paths.
RUN set -eu; \
    mkdir -p /out/lib /out/share/extension /out/licenses/postgresql-${PG_MAJOR}-prioritize; \
    dpkg -L "postgresql-${PG_MAJOR}-prioritize" | while IFS= read -r file; do \
      test -f "$file" || continue; \
      case "$file" in \
        /usr/lib/postgresql/${PG_MAJOR}/lib/*) dest=/out/lib/${file#/usr/lib/postgresql/${PG_MAJOR}/lib/} ;; \
        /usr/share/postgresql/${PG_MAJOR}/*) dest=/out/share/${file#/usr/share/postgresql/${PG_MAJOR}/} ;; \
        *) continue ;; \
      esac; \
      mkdir -p "$(dirname "$dest")"; cp -L "$file" "$dest"; \
    done; \
    cp /usr/share/doc/postgresql-${PG_MAJOR}-prioritize/copyright /out/licenses/postgresql-${PG_MAJOR}-prioritize/copyright; \
    dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' > /out/licenses/build-packages.tsv

FROM scratch
COPY --from=builder /out/ /
USER 65532:65532
