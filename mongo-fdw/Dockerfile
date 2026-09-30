# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

COPY mongo-fdw/patches/mongoc-aggregate-db-order.patch /tmp/mongoc-aggregate-db-order.patch

RUN set -eu; \
    for source_file in /etc/apt/sources.list.d/*.sources; do \
      if [ -f "$source_file" ]; then sed -i "s/^Types: deb$/Types: deb deb-src/" "$source_file"; fi; \
    done; \
    grep -R -q "^Types: deb deb-src$" /etc/apt/sources.list.d; \
    dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\t${db:Status-Abbrev}\n' | awk -F '\t' '$4 ~ /^ii/ {print $1 "\t" $2 "\t" $3}' | sort > /tmp/base-package-inventory.tsv; \
    apt-get update; \
    apt-get install -y --no-install-recommends dpkg-dev "postgresql-${PG_MAJOR}-mongo-fdw=${EXT_VERSION}"; \
    driver_package="$(dpkg-query -W -f='${source:Package}' libmongoc-1.0-0t64)"; \
    driver_version="$(dpkg-query -W -f='${source:Version}' libmongoc-1.0-0t64)"; \
    test "$driver_package" = mongo-c-driver; \
    test "$driver_version" = '1.30.4-1+deb13u3' || { printf 'Unreviewed mongo-c-driver source version: %s\n' "$driver_version" >&2; exit 1; }; \
    apt-get build-dep -y --no-install-recommends "${driver_package}=${driver_version}"; \
    mkdir -p /tmp/mongo-driver-source /tmp/mongo-driver-patched /out/source /out/system /out/licenses; \
    cd /tmp/mongo-driver-source; \
    apt-get source "${driver_package}=${driver_version}"; \
    source_dir="$(find /tmp/mongo-driver-source -mindepth 1 -maxdepth 1 -type d -name 'mongo-c-driver-*' -print -quit)"; \
    test -n "$source_dir"; \
    patch -d "$source_dir" -p1 < /tmp/mongoc-aggregate-db-order.patch; \
    cp -a /tmp/mongoc-aggregate-db-order.patch /out/source/; \
    cp -a /tmp/mongo-driver-source/*.dsc /tmp/mongo-driver-source/*.tar.* /out/source/; \
    printf 'source package: %s %s\nrebuilt component: libmongoc-1.0.so.0\npatch: mongoc-aggregate-db-order.patch (swaps db/ns arguments to _mongoc_aggregate after Debian CVE validation patch)\n' "$driver_package" "$driver_version" > /out/licenses/mongoc-build.txt; \
    cd "$source_dir"; \
    DEB_BUILD_OPTIONS='nocheck nodoc' dpkg-buildpackage -B -uc -us; \
    driver_deb="$(find /tmp/mongo-driver-source -mindepth 1 -maxdepth 1 -type f -name "libmongoc-1.0-0t64_${driver_version}_*.deb" -print -quit)"; \
    test -n "$driver_deb"; \
    dpkg-deb -x "$driver_deb" /tmp/mongo-driver-patched; \
    multiarch="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"; \
    cp -L "/tmp/mongo-driver-patched/usr/lib/${multiarch}/libmongoc-1.0.so.0" /tmp/mongoc-patched-libmongoc.so

# Stage this extension's PostgreSQL artifacts and the exact linked runtime
# libraries for the active Debian suite and target architecture.
RUN set -eu; \
    mkdir -p /out/lib/bitcode /out/share/extension /out/system /out/licenses /out/licenses/runtime /out/licenses/common-licenses; \
    : > /out/licenses/runtime-packages.txt; \
    : > /out/licenses/base-linkages.txt; \
    for library in "/usr/lib/postgresql/${PG_MAJOR}/lib/mongo_fdw.so"; do \
      test -f "$library"; \
      cp -a "$library" /out/lib/; \
      prefix="$(basename "$library" .so)"; \
      if [ -d "/usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/$prefix" ]; then \
        cp -a "/usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/$prefix" /out/lib/bitcode/; \
      fi; \
      if [ -f "/usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/$prefix.index.bc" ]; then \
        cp -a "/usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/$prefix.index.bc" /out/lib/bitcode/; \
      fi; \
    done; \
    for extension_file in /usr/share/postgresql/${PG_MAJOR}/extension/mongo_fdw.control /usr/share/postgresql/${PG_MAJOR}/extension/mongo_fdw--*.sql; do \
      cp -a "$extension_file" /out/share/extension/; \
    done; \
    package="postgresql-${PG_MAJOR}-mongo-fdw"; \
    printf "%s %s %s\n" "$package" "$EXT_VERSION" "$(dpkg-query -W -f='${Architecture}' "$package")" >> /out/licenses/runtime-packages.txt; \
    mkdir -p "/out/licenses/$package"; \
    cp -a "/usr/share/doc/$package/copyright" "/out/licenses/$package/copyright"; \
    for library in "/usr/lib/postgresql/${PG_MAJOR}/lib/mongo_fdw.so"; do \
      missing="$(ldd "$library" | grep "not found" || true)"; \
      if [ -n "$missing" ]; then printf "%s\n" "$missing" >&2; exit 1; fi; \
    done; \
    for library in "/usr/lib/postgresql/${PG_MAJOR}/lib/mongo_fdw.so"; do ldd "$library"; done | \
      awk '$2 == "=>" && $3 ~ /^\// {print $3} $1 ~ /^\// {print $1}' | sort -u | \
      while IFS= read -r dependency; do \
        name="$(basename "$dependency")"; \
        case "$name" in libc.so.*|libm.so.*|libpthread.so.*|libdl.so.*|librt.so.*|libresolv.so.*|libutil.so.*|ld-linux*) continue ;; esac; \
        real="$(readlink -f "$dependency")"; \
        owner=""; \
        for owner_path in "$dependency" "$real" "${real#/usr}"; do \
          [ -n "$owner_path" ] || continue; \
          owner="$(dpkg-query -S "$owner_path" 2>/dev/null | awk '/^diversion / { next } /^[^[:space:]]+: / { sub(/: .*/, ""); print; exit }')"; \
          [ -n "$owner" ] && break; \
        done; \
        test -n "$owner" || { printf "No Debian package owns %s (resolved %s)\n" "$dependency" "$real" >&2; exit 1; }; \
        runtime_package="${owner%%:*}"; \
        runtime_version="$(dpkg-query -W -f='${Version} ${Architecture}' "$owner")"; \
        base_version="$(awk -F '\t' -v package="$runtime_package" '$1 == package { print $2 " " $3; exit }' /tmp/base-package-inventory.tsv)"; \
        if [ -n "$base_version" ] && [ "$base_version" = "$runtime_version" ]; then \
          printf "%s %s\n" "$runtime_package" "$base_version" >> /out/licenses/base-linkages.txt; \
          continue; \
        fi; \
        cp -L "$dependency" "/out/system/$name"; \
        printf "%s %s\n" "$runtime_package" "$runtime_version" >> /out/licenses/runtime-packages.txt; \
        test -f "/usr/share/doc/$runtime_package/copyright"; \
        mkdir -p "/out/licenses/runtime/$runtime_package"; \
        cp -a "/usr/share/doc/$runtime_package/copyright" "/out/licenses/runtime/$runtime_package/copyright"; \
      done; \
    sort -u /out/licenses/runtime-packages.txt -o /out/licenses/runtime-packages.txt; \
    sort -u /out/licenses/base-linkages.txt -o /out/licenses/base-linkages.txt; \
    mkdir -p /out/source; \
    touch /out/licenses/source-packages.txt; \
    printf 'mongo-c-driver %s\n' "$(dpkg-query -W -f='${source:Version}' libmongoc-1.0-0t64)" >> /out/licenses/source-packages.txt; \
    while read -r runtime_package runtime_version; do \
      copyright="/usr/share/doc/$runtime_package/copyright"; \
      if [ -f "$copyright" ] && grep -Eiq "GPL|General Public License|Lesser General Public License" "$copyright"; then \
        source_info="$(dpkg-query -W -f='${source:Package} ${source:Version}' "$runtime_package")"; \
        source_package="${source_info%% *}"; \
        source_version="${source_info#* }"; \
        case "$source_package" in \
          e2fsprogs|gcc-12|gcc-14|gmp|gnutls28|keyutils|libidn2|libtasn1-6|libunistring|libxcrypt|nettle|rtmpdump|mongo-fdw|mongo-c-driver) \
            source_id="$source_package $source_version"; \
            if ! grep -Fxq "$source_id" /out/licenses/source-packages.txt; then \
              printf "%s\n" "$source_id" >> /out/licenses/source-packages.txt; \
              (cd /out/source && apt-get source --download-only "${source_package}=${source_version}"); \
            fi ;; \
          curl|cyrus-sasl2|icu|krb5|libffi|libscrypt|libzstd|nghttp2|nghttp3|openldap|openssl|p11-kit|xz-utils) \
            ;; \
          *) printf "Unreviewed GPL/LGPL runtime package: %s (source %s %s)\n" "$runtime_package" "$source_package" "$source_version" >&2; exit 1 ;; \
        esac; \
      fi; \
    done < /out/licenses/runtime-packages.txt; \
    cp /tmp/mongoc-patched-libmongoc.so /out/system/libmongoc-1.0.so.0; \
    missing="$(LD_LIBRARY_PATH=/out/system ldd "/usr/lib/postgresql/${PG_MAJOR}/lib/mongo_fdw.so" | grep "not found" || true)"; \
    if [ -n "$missing" ]; then printf "%s\n" "$missing" >&2; exit 1; fi; \
    sort -u /out/licenses/source-packages.txt -o /out/licenses/source-packages.txt; \
    rm -rf /var/lib/apt/lists/*; \
    cp -a /usr/share/common-licenses/. /out/licenses/common-licenses/

FROM scratch
ARG PG_MAJOR
COPY --from=builder /out/lib/ /lib/
COPY --from=builder /out/share/extension/ /share/extension/
COPY --from=builder /out/system/ /system/
COPY --from=builder /out/licenses/ /licenses/
COPY --from=builder /out/source/ /source/
USER 65532:65532
