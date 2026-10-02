#!/usr/bin/env python3
"""Assert useful content in the BuildKit smoke SPDX and Trivy report."""

import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"BuildKit SBOM smoke check failed: {message}")


def purl(package: dict) -> str | None:
    for reference in package.get("externalRefs", []):
        if reference.get("referenceType") == "purl":
            return reference.get("referenceLocator")
    return None


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: check_buildkit_smoke.py SPDX_JSON TRIVY_JSON")
    spdx_path, trivy_path = map(Path, sys.argv[1:])
    document = json.loads(spdx_path.read_text(encoding="utf-8"))
    report = json.loads(trivy_path.read_text(encoding="utf-8"))

    packages = document.get("packages", [])
    by_name = {package.get("name"): package for package in packages}
    base_files = by_name.get("base-files")
    if not base_files:
        fail("package-owned Debian base-files package is absent")

    files = {record.get("fileName"): record for record in document.get("files", [])}
    copyright_file = files.get("licenses/copyright")
    if not copyright_file:
        fail("package-owned /licenses/copyright file is absent")
    file_licenses = set(copyright_file.get("licenseInfoInFiles", [])) - {
        "NONE", "NOASSERTION"
    }
    if not file_licenses:
        fail("ScanCode did not identify license evidence in /licenses/copyright")

    base_id = base_files["SPDXID"]
    file_id = copyright_file["SPDXID"]
    ownership = any(
        relation.get("spdxElementId") == base_id
        and relation.get("relatedSpdxElement") == file_id
        and relation.get("relationshipType") == "CONTAINS"
        for relation in document.get("relationships", [])
    )
    if not ownership:
        fail("base-files does not own the final licenses/copyright file")

    crate = next(
        (package for package in packages if purl(package) == "pkg:cargo/sbom-smoke-crate@1.2.3"),
        None,
    )
    if not crate or crate.get("licenseDeclared") != "MIT":
        fail("hook-provided Cargo package or its MIT declaration is absent")

    trivy_packages = [
        package
        for result in report.get("Results", [])
        for package in result.get("Packages", [])
    ]
    cargo_report = next(
        (
            package for package in trivy_packages
            if package.get("Name") == "sbom-smoke-crate"
            and package.get("Version") == "1.2.3"
        ),
        None,
    )
    if not cargo_report or "MIT" not in cargo_report.get("Licenses", []):
        fail("Trivy did not report the hook-provided Cargo package with MIT")

    base_report = next(
        (package for package in trivy_packages if package.get("Name") == "base-files"),
        None,
    )
    base_report_licenses = set((base_report or {}).get("Licenses", [])) - {
        "NONE", "NOASSERTION"
    }
    if not base_report_licenses:
        fail("Trivy did not report license evidence for Debian base-files")

    print(
        "BuildKit SBOM smoke passed: base-files owns /licenses/copyright "
        f"({', '.join(sorted(file_licenses))}); hook Cargo crate is MIT; "
        f"Trivy reports base-files ({', '.join(sorted(base_report_licenses))})"
    )


if __name__ == "__main__":
    main()
