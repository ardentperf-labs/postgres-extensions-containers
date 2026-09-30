ARG BUILDKIT_SBOM_SCAN_STAGE=builder
FROM scratch AS builder
COPY status /var/lib/dpkg/status
COPY os-release /etc/os-release
COPY payload /usr/share/probe/payload
COPY augment_spdx.py /usr/local/share/cnpg-sbom/augment_spdx.py
FROM scratch
COPY --from=builder /usr/share/probe/payload /payload
