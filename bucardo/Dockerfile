# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0

ARG BASE=ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
FROM $BASE AS builder

ARG PG_MAJOR
ARG EXT_VERSION

USER 0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      "bucardo=${EXT_VERSION}"

FROM scratch
ARG PG_MAJOR

# Licenses
COPY --from=builder /usr/share/doc/bucardo/copyright /licenses/bucardo/
# Libraries
# Bucardo uses the separately supplied PL/Perl image.

# Share
COPY --from=builder /usr/share/bucardo/bucardo.schema /share/extension/bucardo.schema

USER 65532:65532
