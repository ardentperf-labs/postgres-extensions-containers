# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-pltcl-${PG_MAJOR}=${EXT_VERSION}" \
      libtcl8.6 \
    && rm -rf /var/lib/apt/lists/*

# Preserve the exact PGDG PostgreSQL and Debian Tcl source packages associated
# with the shipped PL/Tcl module and Tcl interpreter.
RUN set -eu; \
    . /etc/os-release; \
    sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources; \
    printf 'deb-src [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$VERSION_CODENAME" > /etc/apt/sources.list.d/pgdg-src.list; \
    apt-get update; \
    mkdir -p /tmp/source-downloads; \
    cd /tmp/source-downloads; \
    source_specs=$(for package in "postgresql-pltcl-${PG_MAJOR}" libtcl8.6; do \
      source_package=$(dpkg-query -W -f='${source:Package}' "$package"); \
      source_version=$(dpkg-query -W -f='${source:Version}' "$package"); \
      printf '%s=%s\n' "$source_package" "$source_version"; \
    done | sort -u); \
    printf '%s\n' "$source_specs" | while IFS= read -r source_spec; do apt-get source --download-only "$source_spec"; done; \
    rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    mkdir -p /tmp/artifact/lib; \
    tcl_library=$(ldd "/usr/lib/postgresql/${PG_MAJOR}/lib/pltcl.so" | awk '$1 == "libtcl8.6.so" {print $3}'); \
    [ -n "$tcl_library" ] || { echo 'libtcl8.6.so not found in pltcl.so dependency closure' >&2; exit 1; }; \
    cp -L "$tcl_library" /tmp/artifact/lib/libtcl8.6.so; \
    cp -a /usr/share/tcltk/tcl8.6 /tmp/artifact/tcl8.6; \
    test -s /tmp/artifact/tcl8.6/init.tcl; \
    runtime_packages="postgresql-pltcl-${PG_MAJOR} libtcl8.6 postgresql-${PG_MAJOR}"; \
    for extension_object in "/usr/lib/postgresql/${PG_MAJOR}/lib/pltcl.so" /tmp/artifact/lib/libtcl8.6.so; do \
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

COPY --from=builder /usr/share/doc/postgresql-pltcl-${PG_MAJOR}/copyright /licenses/postgresql-pltcl/copyright
COPY --from=builder /usr/share/doc/libtcl8.6/copyright /licenses/libtcl8.6/copyright
COPY --from=builder /usr/share/common-licenses/GPL-1 /licenses/GPL-1
COPY --from=builder /usr/share/common-licenses/Artistic /licenses/Artistic
COPY --from=builder /tmp/source-downloads/ /source/
COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv
COPY --from=builder /tmp/artifact/lib/libtcl8.6.so /lib/libtcl8.6.so
COPY --from=builder /tmp/artifact/tcl8.6/ /share/tcl8.6/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/pltcl.so /lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/pltcl* /share/extension/

USER 65532:65532
