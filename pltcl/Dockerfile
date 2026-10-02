# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

# Capture base image libraries before installing extension packages.
COPY scripts/capture_base_image_libs.sh /usr/local/bin/capture_base_image_libs.sh
RUN /usr/local/bin/capture_base_image_libs.sh

RUN apt-get update && apt-get install -y --no-install-recommends \
      "postgresql-pltcl-${PG_MAJOR}=${EXT_VERSION}"

# Gather system libraries and their licenses
COPY scripts/stage_system_libs.sh /usr/local/bin/stage_system_libs.sh

RUN /usr/local/bin/stage_system_libs.sh \
      "/usr/lib/postgresql/${PG_MAJOR}/lib/pltcl.so"

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /licenses /licenses/
COPY --from=builder /usr/share/doc/postgresql-pltcl-${PG_MAJOR}/copyright /licenses/postgresql-pltcl-${PG_MAJOR}/copyright

# Libraries
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/pltcl.so /lib/

# Share
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/pltcl* /share/extension/
COPY --from=builder /usr/share/tcltk/tcl8.6/ /share/tcl8.6/

# System libs
COPY --from=builder /system /system/

USER 65532:65532
