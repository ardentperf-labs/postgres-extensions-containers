# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder
ARG PG_MAJOR
ARG EXT_VERSION
USER 0

RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-plperl-${PG_MAJOR}=${EXT_VERSION}" libdbi-perl libdbd-pg-perl perl

# Stage Perl modules and their licenses.
RUN set -eu; \
    . /etc/os-release; \
    case "$VERSION_CODENAME" in \
      bookworm) perl_version=5.36; perl_core=libperl5.36 ;; \
      trixie) perl_version=5.40; perl_core=libperl5.40 ;; \
      *) echo "unsupported Debian suite: $VERSION_CODENAME" >&2; exit 1 ;; \
    esac; \
    mkdir -p /tmp/perl/arch /tmp/perl/share /tmp/perl/vendor-arch /tmp/perl/vendor-share; \
    for directory in /usr/lib/*/perl/${perl_version}; do cp -aL "$directory/." /tmp/perl/arch/; done; \
    cp -aL "/usr/share/perl/${perl_version}/." /tmp/perl/share/; \
    for directory in /usr/lib/*/perl5/${perl_version}; do cp -aL "$directory/." /tmp/perl/vendor-arch/; done; \
    cp -aL /usr/share/perl5/. /tmp/perl/vendor-share/; \
    mkdir -p "/licenses/${perl_core}" /licenses/perl; \
    cp "/usr/share/doc/${perl_core}/copyright" "/licenses/${perl_core}/copyright"; \
    cp /usr/share/doc/perl/copyright /licenses/perl/copyright

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses/ /licenses/
COPY --from=builder /usr/share/doc/postgresql-plperl-${PG_MAJOR}/copyright /licenses/postgresql-plperl-${PG_MAJOR}/copyright
COPY --from=builder /usr/share/doc/libdbi-perl/copyright /licenses/libdbi-perl/copyright
COPY --from=builder /usr/share/doc/libdbd-pg-perl/copyright /licenses/libdbd-pg-perl/copyright

# Libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/*plperl*.so /lib/

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/*plperl* /share/extension/

# Runtime
COPY --from=builder /tmp/perl/ /perl/

USER 65532:65532
