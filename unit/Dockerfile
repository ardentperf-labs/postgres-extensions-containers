# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# The CNPG base image supplies PostgreSQL and the system runtime libraries.
RUN apt-get update && apt-get install -y --no-install-recommends \
      patch \
      "postgresql-${PG_MAJOR}-unit=${EXT_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# PGDG's SQL files hard-code the package's Debian share directory. In a CNPG
# extension image, the data files are mounted below /extensions/unit instead.
COPY unit/patches/0001-use-cnpg-mounted-data-files.patch /tmp/
RUN set -eu; \
    extension_dir="/usr/share/postgresql/${PG_MAJOR}/extension"; \
    patch --dry-run --batch -p1 -d "$extension_dir" < /tmp/0001-use-cnpg-mounted-data-files.patch; \
    patch --batch -p1 -d "$extension_dir" < /tmp/0001-use-cnpg-mounted-data-files.patch; \
    if grep -F "/usr/share/postgresql/${PG_MAJOR}/extension/unit_prefixes.data" "$extension_dir"/unit--*.sql \
       || grep -F "/usr/share/postgresql/${PG_MAJOR}/extension/unit_units.data" "$extension_dir"/unit--*.sql; then \
      echo 'unit SQL still references Debian package data paths' >&2; exit 1; \
    fi; \
    patched_count=$(grep -hF '/extensions/unit/share/extension/unit_' "$extension_dir"/unit--*.sql | wc -l); \
    test "$patched_count" -eq 14

# Download the exact corresponding PGDG source package selected by installed binary metadata.
RUN set -eu; \
    . /etc/os-release; \
    printf 'deb-src [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$VERSION_CODENAME" > /etc/apt/sources.list.d/pgdg-src.list; \
    apt-get update; \
    mkdir -p /tmp/source-downloads; \
    cd /tmp/source-downloads; \
    package="postgresql-${PG_MAJOR}-unit"; \
    source_package=$(dpkg-query -W -f='${source:Package}' "$package"); \
    source_version=$(dpkg-query -W -f='${source:Version}' "$package"); \
    apt-get source --download-only "${source_package}=${source_version}"; \
    rm -rf /var/lib/apt/lists/*

# Record the installed extension, server, and actual shared-library providers.
RUN set -eu; \
    runtime_packages="postgresql-${PG_MAJOR}-unit postgresql-${PG_MAJOR}"; \
    for extension_object in /usr/lib/postgresql/${PG_MAJOR}/lib/unit*.so; do \
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
COPY --from=builder /usr/share/doc/postgresql-${PG_MAJOR}-unit/copyright /licenses/postgresql-${PG_MAJOR}-unit/
COPY --from=builder /usr/share/common-licenses/GPL-3 /licenses/GPL-3
# Corresponding PGDG source archives (upstream orig tarball, .dsc, Debian packaging).
COPY --from=builder /tmp/source-downloads/ /source/
COPY --from=builder /tmp/0001-use-cnpg-mounted-data-files.patch /source/patches/0001-use-cnpg-mounted-data-files.patch
COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv

# Extension shared object.
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/unit* /lib/

# Extension control file and SQL installation/upgrade scripts.
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/unit* /share/extension/

USER 65532:65532
