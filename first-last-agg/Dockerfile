# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# The CNPG base image supplies PostgreSQL and the system runtime libraries.
RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-first-last-agg=${EXT_VERSION}" \
    && rm -rf /var/lib/apt/lists/*


# Record the installed extension, server, and actual shared-library providers.
RUN set -eu; \
    runtime_packages="postgresql-${PG_MAJOR}-first-last-agg postgresql-${PG_MAJOR}"; \
    for extension_object in /usr/lib/postgresql/${PG_MAJOR}/lib/first_last_agg*.so; do \
      [ -e "$extension_object" ] || continue; \
      ldd "$extension_object" > /tmp/extension-ldd.txt; \
      if grep -q 'not found' /tmp/extension-ldd.txt; then cat /tmp/extension-ldd.txt >&2; exit 1; fi; \
      for library_path in $(awk '$2 == "=>" && $3 ~ /^\// {print $3} $1 ~ /^\// {print $1}' /tmp/extension-ldd.txt); do \
        resolved_library_path=$(readlink -f "$library_path"); \
        owner=""; \
        for owner_path in "$library_path" "$resolved_library_path" "${resolved_library_path#/usr}"; do \
          [ -n "$owner_path" ] || continue; \
          owner=$(dpkg-query -S "$owner_path" 2>/dev/null | awk '/^diversion / { next } /^[^[:space:]]+: / { sub(/: .*/, ""); print; exit }'); \
          [ -n "$owner" ] && break; \
        done; \
        [ -n "$owner" ] || { echo "no Debian package owns $library_path (resolved $resolved_library_path)" >&2; exit 1; }; \
        runtime_packages="$runtime_packages $owner"; \
      done; \
    done; \
    { \
      printf '# binary-package\tversion\tsource-package\tsource-version\n'; \
      for package in $(printf '%s\n' "$runtime_packages" | tr ' ' '\n' | sed '/^$/d' | sort -u); do \
        dpkg-query -W -f='${binary:Package}\t${Version}\t${source:Package}\t${source:Version}\n' "$package"; \
      done; \
    } | awk 'NR == 1 { print; next } !seen[$0]++' > /tmp/runtime-packages.tsv

FROM scratch
ARG PG_MAJOR

# Debian copyright file includes upstream attribution and package license terms.
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-first-last-agg/copyright /licenses/postgresql-${PG_MAJOR}-first-last-agg/
COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv

# Extension shared object.
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/first_last_agg* /lib/

# Extension control file and SQL installation/upgrade scripts.
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/first_last_agg* /share/extension/

USER 65532:65532
