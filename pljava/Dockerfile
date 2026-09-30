# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie

# Keep the CNPG base package set so the extension image copies only runtime
# dependencies that the target server image does not already provide.
FROM $BASE AS base-packages
USER 0
RUN dpkg-query -W -f='${binary:Package}\n' | sort -u > /tmp/base-packages.list

FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# PL/Java 1.6.10 supports policy enforcement on Java 17 and Java 21. Keep the
# runtime on those Debian-supported LTS releases: Bookworm supplies 17, Trixie 21.
RUN set -eu; \
    . /etc/os-release; \
    case "$VERSION_CODENAME" in \
      bookworm) jre_package=openjdk-17-jre-headless ;; \
      trixie) jre_package=openjdk-21-jre-headless ;; \
      *) echo "unsupported Debian suite: $VERSION_CODENAME" >&2; exit 1 ;; \
    esac; \
    printf '%s\n' "$jre_package" > /tmp/jre-package; \
    apt-get update; \
    apt-get install -y \
      "postgresql-${PG_MAJOR}-pljava=${EXT_VERSION}" \
      "$jre_package"; \
    rm -rf /var/lib/apt/lists/*

COPY --from=base-packages /tmp/base-packages.list /tmp/base-packages.list

# Put the complete Debian-selected headless runtime in a stable image-volume
# location, dereferencing package alternatives and configuration symlinks.
RUN set -eu; \
    jre_home=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")"); \
    test -s "$jre_home/lib/server/libjvm.so"; \
    printf '%s\n' "$jre_home" > /tmp/jre-home; \
    mkdir -p /tmp/jvm /tmp/licenses/openjdk; \
    cp -aL "$jre_home/." /tmp/jvm/; \
    jre_package=$(cat /tmp/jre-package); \
    cp "/usr/share/doc/${jre_package}/copyright" /tmp/licenses/openjdk/copyright; \
    cp /etc/postgresql-common/pljava.policy /tmp/pljava.policy

# Record the extension, JVM, every native JVM module, and the complete ELF
# dependency closure. Copy external runtime libraries only when they are absent
# from the matching CNPG base image; the JRE's own libraries are already copied.
RUN set -eu; \
    jre_package=$(cat /tmp/jre-package); \
    jre_home=$(cat /tmp/jre-home); \
    runtime_packages="postgresql-${PG_MAJOR}-pljava postgresql-pljava-common ${jre_package} postgresql-${PG_MAJOR}"; \
    redistributed_packages="postgresql-${PG_MAJOR}-pljava postgresql-pljava-common ${jre_package}"; \
    mkdir -p /tmp/artifact/runtime-libs; \
    find "$jre_home" -type f -name '*.so' -print > /tmp/jre-native-modules.list; \
    { printf '%s\n' "/usr/lib/postgresql/${PG_MAJOR}/lib/libpljava-so-1.6.10.so" "$jre_home/bin/java"; cat /tmp/jre-native-modules.list; } > /tmp/runtime-objects.list; \
    : > /tmp/runtime-library-paths.list; \
    while IFS= read -r extension_object; do \
      LD_LIBRARY_PATH="$jre_home/lib/server:$jre_home/lib" ldd "$extension_object" > /tmp/extension-ldd.txt; \
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
        case "$resolved_library_path" in "$jre_home"/*) ;; *) printf '%s\n' "$library_path" >> /tmp/runtime-library-paths.list ;; esac; \
      done; \
    done < /tmp/runtime-objects.list; \
    sort -u /tmp/runtime-library-paths.list -o /tmp/runtime-library-paths.list; \
    for library_path in $(cat /tmp/runtime-library-paths.list); do \
      resolved_library_path=$(readlink -f "$library_path"); \
      owner=""; \
      for owner_path in "$library_path" "$resolved_library_path" "${resolved_library_path#/usr}"; do \
        [ -n "$owner_path" ] || continue; \
        owner=$(dpkg-query -S "$owner_path" 2>/dev/null | awk '/^diversion / { next } /^[^[:space:]]+: / { sub(/: .*/, ""); print; exit }'); \
        [ -n "$owner" ] && break; \
      done; \
      [ -n "$owner" ] || { echo "no Debian package owns $library_path" >&2; exit 1; }; \
      if ! grep -Fxq "$owner" /tmp/base-packages.list; then \
        cp -L "$library_path" "/tmp/artifact/runtime-libs/$(basename "$library_path")"; \
        redistributed_packages="$redistributed_packages $owner"; \
      fi; \
    done; \
    { \
      printf '# binary-package\tversion\tsource-package\tsource-version\n'; \
      for package in $(printf '%s\n' "$runtime_packages" | tr ' ' '\n' | sed '/^$/d' | sort -u); do \
        dpkg-query -W -f='${binary:Package}\t${Version}\t${source:Package}\t${source:Version}\n' "$package"; \
      done; \
    } | awk 'NR == 1 { print; next } !seen[$0]++' > /tmp/runtime-packages.tsv; \
    printf '%s\n' "$redistributed_packages" | tr ' ' '\n' | sed '/^$/d' | sort -u > /tmp/redistributed-packages.list

# Preserve exact source packages for PL/Java, its policy companion, the JRE,
# and every external native library copied into the image volume.
RUN set -eu; \
    . /etc/os-release; \
    sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources; \
    printf 'deb-src [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$VERSION_CODENAME" > /etc/apt/sources.list.d/pgdg-src.list; \
    apt-get update; \
    mkdir -p /tmp/source-downloads /tmp/licenses/packages; \
    cd /tmp/source-downloads; \
    source_specs=$(while IFS= read -r package; do \
      source_package=$(dpkg-query -W -f='${source:Package}' "$package"); \
      source_version=$(dpkg-query -W -f='${source:Version}' "$package"); \
      printf '%s=%s\n' "$source_package" "$source_version"; \
    done < /tmp/redistributed-packages.list | sort -u); \
    printf '%s\n' "$source_specs" | while IFS= read -r source_spec; do apt-get source --download-only "$source_spec"; done; \
    while IFS= read -r package; do \
      package_name=${package%%:*}; \
      copyright="/usr/share/doc/${package_name}/copyright"; \
      [ -r "$copyright" ] || { echo "missing copyright notice for redistributed package $package" >&2; exit 1; }; \
      mkdir -p "/tmp/licenses/packages/${package_name}"; \
      cp "$copyright" "/tmp/licenses/packages/${package_name}/copyright"; \
    done < /tmp/redistributed-packages.list; \
    rm -rf /var/lib/apt/lists/*

FROM scratch
ARG PG_MAJOR

COPY --from=builder /tmp/licenses/packages/ /licenses/packages/
COPY --from=builder /tmp/licenses/openjdk/ /licenses/openjdk/
COPY --from=builder /usr/share/common-licenses/ /licenses/common-licenses/
COPY --from=builder /tmp/source-downloads/ /source/
COPY --from=builder /tmp/runtime-packages.tsv /licenses/runtime-packages.tsv
COPY --from=builder /tmp/pljava.policy /share/pljava.policy
COPY --from=builder /tmp/jvm/ /jvm/
COPY --from=builder /tmp/artifact/runtime-libs/ /lib/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/libpljava-so-1.6.10.so /lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/pljava.control /share/extension/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/pljava/ /share/pljava/

USER 65532:65532
