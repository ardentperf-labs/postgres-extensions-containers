#!/usr/bin/env python3
"""Apply narrowly scoped build-only overrides for temporary regression runs."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path


PINS = {
    "bookworm": {
        "version": "2.10.9-1.pgdg12+1",
        "amd64": {
            "sha256": "b68281c756dd400dabd9c92e46387dd24636f2c4a63b6342679b10807bf675e8",
            "filename": "postgresql-18-plpgsql-check_2.10.9-1.pgdg12+1_amd64.deb",
        },
        "arm64": {
            "sha256": "cce0e382f9f945157d00801db594571393b6fe5220f6109fe798290b013a1e25",
            "filename": "postgresql-18-plpgsql-check_2.10.9-1.pgdg12+1_arm64.deb",
        },
    },
    "trixie": {
        "version": "2.10.9-1.pgdg13+1",
        "amd64": {
            "sha256": "44e43697a8a834a99188e288eadf8d279994a5d78bfa21156f86e3679fbf6423",
            "filename": "postgresql-18-plpgsql-check_2.10.9-1.pgdg13+1_amd64.deb",
        },
        "arm64": {
            "sha256": "7d80ff4662533d524d940276f6f9b0f68866267b3141e3449ac665f31b1ec3fd",
            "filename": "postgresql-18-plpgsql-check_2.10.9-1.pgdg13+1_arm64.deb",
        },
    },
}

ORIGINAL_INSTALL = '''RUN apt-get update && \\
    apt-get install -y --no-install-recommends \\
      "postgresql-${PG_MAJOR}-plpgsql-check=${EXT_VERSION}"'''

ARCHIVED_INSTALL = '''COPY --from=fetcher /tmp/plpgsql-check.deb /tmp/plpgsql-check.deb

RUN apt-get update && \\
    apt-get install -y --no-install-recommends /tmp/plpgsql-check.deb'''


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("extension")
    parser.add_argument("architecture", choices=("amd64", "arm64"))
    args = parser.parse_args()
    if args.extension != "plpgsql-check":
        return

    dockerfile = Path(args.extension) / "Dockerfile"
    original = dockerfile.read_text()
    if ORIGINAL_INSTALL not in original:
        raise SystemExit("plpgsql-check Dockerfile no longer matches the expected exact-pin install step")

    fetcher = '''FROM $BASE AS fetcher
ARG BASE
ARG TARGETARCH
ARG EXT_VERSION
USER 0

RUN apt-get update && \\
    apt-get install -y --no-install-recommends ca-certificates curl

RUN set -eux; \\
    case "$BASE:$TARGETARCH" in \\
        *bookworm:amd64) expected=b68281c756dd400dabd9c92e46387dd24636f2c4a63b6342679b10807bf675e8; filename=postgresql-18-plpgsql-check_2.10.9-1.pgdg12+1_amd64.deb ;; \\
        *bookworm:arm64) expected=cce0e382f9f945157d00801db594571393b6fe5220f6109fe798290b013a1e25; filename=postgresql-18-plpgsql-check_2.10.9-1.pgdg12+1_arm64.deb ;; \\
        *trixie:amd64) expected=44e43697a8a834a99188e288eadf8d279994a5d78bfa21156f86e3679fbf6423; filename=postgresql-18-plpgsql-check_2.10.9-1.pgdg13+1_amd64.deb ;; \\
        *trixie:arm64) expected=7d80ff4662533d524d940276f6f9b0f68866267b3141e3449ac665f31b1ec3fd; filename=postgresql-18-plpgsql-check_2.10.9-1.pgdg13+1_arm64.deb ;; \\
        *) echo "unsupported archived pin platform: $BASE / $TARGETARCH" >&2; exit 1 ;; \\
    esac; \\
    curl --fail --silent --show-error --location \\
      "https://apt-archive.postgresql.org/pub/repos/apt/pool/main/p/plpgsql-check/$filename" \\
      --output /tmp/plpgsql-check.deb; \\
    printf '%s  %s\\n' "$expected" /tmp/plpgsql-check.deb | sha256sum --check --strict -

FROM $BASE AS builder
ARG PG_MAJOR
ARG EXT_VERSION
USER 0
'''

    updated = original.replace(
        "FROM $BASE AS builder\n\nARG PG_MAJOR\nARG EXT_VERSION\n\nUSER 0\n",
        fetcher,
        1,
    ).replace(ORIGINAL_INSTALL, ARCHIVED_INSTALL, 1)
    if updated == original or "FROM $BASE AS fetcher" not in updated:
        raise SystemExit("validation override did not modify the Dockerfile")

    runner_temp = Path(os.environ["RUNNER_TEMP"])
    evidence_dir = runner_temp / "licensing-evidence" / f"{args.extension}-{args.architecture}"
    evidence_dir.mkdir(parents=True, exist_ok=True)
    (evidence_dir / "validation-override.json").write_text(
        json.dumps(
            {
                "override": "archive-pgdg-exact-pin-v1",
                "extension": args.extension,
                "architecture": args.architecture,
                "original_dockerfile_sha256": hashlib.sha256(original.encode()).hexdigest(),
                "override_dockerfile_sha256": hashlib.sha256(updated.encode()).hexdigest(),
                "repository": "https://apt-archive.postgresql.org/pub/repos/apt",
                "packages_index_evidence": "apt-metadata/plpgsql-check-package-indexes.json",
                "pins": PINS,
                "install_method": "fetch exact official archived .deb; verify SHA256; install local .deb while resolving remaining dependencies from configured production repositories",
            },
            indent=2,
        )
        + "\n"
    )
    dockerfile.write_text(updated)


if __name__ == "__main__":
    main()
