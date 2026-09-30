# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-pllua=${EXT_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Include the exact PL/Lua and dynamically linked Lua source packages. The
# extension also installs the optional hstore transforms; hstore itself comes
# from the matching CNPG PostgreSQL base image.
RUN set -eu; \
    . /etc/os-release; \
    sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources; \
    printf 'deb-src [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$VERSION_CODENAME" > /etc/apt/sources.list.d/pgdg-src.list; \
    apt-get update; \
    mkdir -p /tmp/source-downloads; \
    cd /tmp/source-downloads; \
    source_specs=$(for package in "postgresql-${PG_MAJOR}-pllua" liblua5.3-0; do \
      source_package=$(dpkg-query -W -f='${source:Package}' "$package"); \
      source_version=$(dpkg-query -W -f='${source:Version}' "$package"); \
      printf '%s=%s\n' "$source_package" "$source_version"; \
    done | sort -u); \
    printf '%s\n' "$source_specs" | while IFS= read -r source_spec; do apt-get source --download-only "$source_spec"; done; \
    rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    mkdir -p /tmp/artifact/lib; \
    lua_library=$(ldd "/usr/lib/postgresql/${PG_MAJOR}/lib/pllua.so" | awk '$1 == "liblua5.3.so.0" {print $3}'); \
    [ -n "$lua_library" ] || { echo 'liblua5.3.so.0 not found in pllua.so dependency closure' >&2; exit 1; }; \
    cp -L "$lua_library" /tmp/artifact/lib/liblua5.3.so.0; \
    runtime_packages="postgresql-${PG_MAJOR}-pllua liblua5.3-0 postgresql-${PG_MAJOR}"; \
    for extension_object in "/usr/lib/postgresql/${PG_MAJOR}/lib/pllua.so" "/usr/lib/postgresql/${PG_MAJOR}/lib/hstore_pllua.so" /tmp/artifact/lib/liblua5.3.so.0; do \
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

COPY --from=builder /usr/share/doc/postgresql-18-pllua/copyright /licenses/postgresql-18-pllua/copyright
COPY --from=builder /usr/share/doc/liblua5.3-0/copyright /licenses/liblua5.3-0/copyright
COPY --from=builder /tmp/source-downloads/ /source/
COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv
COPY --from=builder /tmp/artifact/lib/liblua5.3.so.0 /lib/liblua5.3.so.0
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/*pllua*.so /lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/*pllua* /share/extension/

USER 65532:65532
