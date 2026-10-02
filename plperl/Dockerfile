# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder
ARG PG_MAJOR
ARG EXT_VERSION
USER 0

RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-plperl-${PG_MAJOR}=${EXT_VERSION}" libdbi-perl libdbd-pg-perl perl

# Dereference runtime symlinks before copying into the final image.
RUN set -eu; \
    mkdir -p /tmp/perl/arch /tmp/perl/share /tmp/perl/vendor-arch /tmp/perl/vendor-share; \
    cp -aL "$(perl -MConfig -e 'print $Config{archlib}')/." /tmp/perl/arch/; \
    cp -aL "$(perl -MConfig -e 'print $Config{privlib}')/." /tmp/perl/share/; \
    cp -aL "$(perl -MConfig -e 'print $Config{vendorarch}')/." /tmp/perl/vendor-arch/; \
    cp -aL "$(perl -MConfig -e 'print $Config{vendorlib}')/." /tmp/perl/vendor-share/

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /usr/share/doc/perl/copyright /licenses/perl/copyright
COPY --from=builder /usr/share/doc/libperl*/copyright /licenses/libperl/copyright
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
