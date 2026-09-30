#!/usr/bin/env python3
"""Compose a platform-specific SPDX predicate for the BuildKit SBOM protocol.

The composer deliberately knows nothing about OCI indexes or in-toto
statements. The generator adds the protocol statement around this predicate;
BuildKit supplies the attestation manifest and binds it to the platform image.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from collections import defaultdict
from copy import deepcopy
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlsplit

from spdx_tools.common.spdx_licensing import spdx_licensing


GENERATOR_NAME = "cnpg-sbom-generator"
GENERATOR_REPOSITORY = "https://github.com/cnpg-extensions/postgres-extensions-containers"
LICENSE_REF = re.compile(r"LicenseRef-[A-Za-z0-9][A-Za-z0-9.-]*")
LICENSE_OPERATOR = re.compile(r"\s+(?:AND|OR|WITH)\s+")


def read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def builder_predicate(document: dict[str, Any], path: Path) -> dict[str, Any]:
    """Return a raw SPDX document from either Syft or an old attestation.

    The old PR61 fixtures are accepted so the ownership algorithm can be
    regression-tested without making an in-toto statement part of the
    generator's input or output contract.
    """

    if document.get("predicateType") == "https://spdx.dev/Document":
        predicate = document.get("predicate")
    else:
        predicate = document
    if not isinstance(predicate, dict) or predicate.get("SPDXID") != "SPDXRef-DOCUMENT":
        raise ValueError(f"{path}: builder evidence is not an SPDX document")
    for field in ("packages", "files", "relationships"):
        if not isinstance(predicate.get(field), list):
            raise ValueError(f"{path}: SPDX {field} must be an array")
    return predicate


def checksum_key(algorithm: str, value: str) -> tuple[str, str]:
    return algorithm.lower(), value.lower()


def final_files(document: dict[str, Any], path: Path) -> list[dict[str, str]]:
    """Return final file names and checksums from a BuildKit attestation."""

    files: list[dict[str, str]] = []
    for subject in document["subject"]:
        name = subject["name"]
        if name.startswith("pkg:"):
            raise ValueError(
                f"{path}: subject {name!r} is an image subject; use a local-export SBOM"
            )
        files.append({
            "name": name.lstrip("/"),
            "algorithm": "sha256",
            "value": subject["digest"]["sha256"],
        })
    if not files:
        raise ValueError(f"{path}: final image has no file subjects")
    return files


def final_inventory_files(inventory: dict[str, Any] | list[dict[str, Any]], path: Path) -> list[dict[str, Any]]:
    """Validate and normalize the generator's direct final-files inventory."""

    records = inventory.get("files") if isinstance(inventory, dict) else inventory
    if not isinstance(records, list) or not records:
        raise ValueError(f"{path}: final filesystem has no files")

    files: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str]] = set()
    for record in records:
        if not isinstance(record, dict):
            raise ValueError(f"{path}: final inventory entry is not an object")
        name = record.get("name", record.get("fileName"))
        if not isinstance(name, str) or not name or name.startswith("pkg:"):
            raise ValueError(f"{path}: final inventory has an invalid file name")
        checksums = record.get("checksums")
        if checksums is not None:
            if not isinstance(checksums, list) or not checksums:
                raise ValueError(f"{path}: final inventory entries need checksums")
            normalized_checksums = []
            for checksum in checksums:
                if not isinstance(checksum, dict):
                    raise ValueError(f"{path}: final inventory checksum is not an object")
                checksum_algorithm = checksum.get("algorithm")
                checksum_value = checksum.get("checksumValue")
                if not isinstance(checksum_algorithm, str) or not isinstance(checksum_value, str) or not checksum_value:
                    raise ValueError(f"{path}: final inventory checksum is incomplete")
                normalized_checksums.append({
                    "algorithm": checksum_algorithm.upper(),
                    "checksumValue": checksum_value.lower(),
                })
            sha256_checksum = next(
                (item for item in normalized_checksums if item["algorithm"] == "SHA256"),
                None,
            )
            primary = sha256_checksum or normalized_checksums[0]
            algorithm = primary["algorithm"]
            value = primary["checksumValue"]
        else:
            algorithm = record.get("algorithm", "sha256")
            value = record.get("value")
            normalized_checksums = [{
                "algorithm": str(algorithm).upper(),
                "checksumValue": str(value).lower() if isinstance(value, str) else value,
            }]
        if not isinstance(algorithm, str) or not isinstance(value, str) or not value:
            raise ValueError(f"{path}: final inventory entry has no checksum")
        normalized = {
            "name": name.lstrip("/"),
            "algorithm": algorithm.lower(),
            "value": value.lower(),
            "checksums": normalized_checksums,
        }
        identity = (normalized["name"], normalized["algorithm"], normalized["value"])
        if identity not in seen:
            files.append(normalized)
            seen.add(identity)
    files.sort(key=lambda record: (record["name"], record["algorithm"], record["value"]))
    return files


def path_score(candidate: str, final_name: str) -> tuple[int, int]:
    """Prefer an exact path, then the longest shared path suffix."""

    candidate_parts = tuple(part for part in candidate.lstrip("/").split("/") if part)
    final_parts = tuple(part for part in final_name.lstrip("/").split("/") if part)
    common_suffix = 0
    for candidate_part, final_part in zip(reversed(candidate_parts), reversed(final_parts)):
        if candidate_part != final_part:
            break
        common_suffix += 1
    return common_suffix, int(candidate_parts == final_parts)


def file_id(name: str, algorithm: str, value: str) -> str:
    identity = f"{name}\0{algorithm.lower()}:{value.lower()}".encode()
    return f"SPDXRef-File-final-{hashlib.sha256(identity).hexdigest()[:24]}"


def scancode_licenses(
    document: dict[str, Any],
) -> tuple[dict[str, set[str]], dict[str, dict[str, str]], dict[str, list[str]]]:
    """Return valid ScanCode expressions, definitions, and invalid-match evidence."""

    licenses_by_file: defaultdict[str, set[str]] = defaultdict(set)
    comments_by_file: defaultdict[str, list[str]] = defaultdict(list)
    custom_licenses: set[str] = set()

    def parse_expression(expression: str) -> tuple[str | None, str | None]:
        try:
            return str(spdx_licensing.parse(expression, validate=False, strict=True)), None
        except Exception as error:
            return None, str(error)

    for record in document.get("files", []):
        path = record["path"].lstrip("/")
        for detection in record.get("license_detections", []):
            expression = detection.get("license_expression_spdx")
            if not expression or expression in {"NONE", "NOASSERTION"}:
                continue

            parsed_expression, parse_error = parse_expression(expression)
            if parsed_expression is not None:
                licenses_by_file[path].add(parsed_expression)
                continue

            # ScanCode sometimes aggregates separate matches into an expression
            # that SPDX cannot represent (for example, an exception without
            # its governing license). Keep every valid match expression, while
            # retaining the invalid raw finding as file-level evidence.
            matched_licenses: set[str] = set()
            invalid_matches: list[str] = []
            for match in detection.get("matches", []):
                match_expression = match.get("license_expression_spdx")
                if not match_expression or match_expression in {"NONE", "NOASSERTION"}:
                    continue
                parsed_match, match_error = parse_expression(match_expression)
                if parsed_match is not None:
                    matched_licenses.add(parsed_match)
                    continue
                rule = match.get("rule_identifier")
                start_line = match.get("start_line")
                end_line = match.get("end_line")
                lines = (
                    f"lines {start_line}-{end_line}"
                    if start_line is not None and end_line is not None
                    else f"line {start_line}"
                    if start_line is not None
                    else "line range unavailable"
                )
                invalid_matches.append(
                    f"{match_expression!r} ({rule or 'ScanCode rule unavailable'}, {lines}; "
                    f"{match_error or 'not a valid SPDX expression'})"
                )

            licenses_by_file[path].update(matched_licenses)
            retained = ", ".join(sorted(matched_licenses)) or "none"
            comment = (
                f"ScanCode reported {expression!r}, which is not a valid SPDX license expression"
                f" ({parse_error}). Valid match expressions retained: {retained}."
            )
            if invalid_matches:
                comment += " Match evidence without a valid SPDX expression: " + "; ".join(
                    sorted(invalid_matches)
                ) + "."
            comments_by_file[path].append(comment)

    licenses = set().union(*licenses_by_file.values()) if licenses_by_file else set()
    custom_licenses.update(
        license_id for expression in licenses for license_id in LICENSE_REF.findall(expression)
    )
    references = {
        reference["spdx_license_key"]: {
            "extractedText": reference.get("text") or "NOASSERTION",
            "licenseId": reference["spdx_license_key"],
            "name": reference.get("name") or reference["spdx_license_key"],
        }
        for reference in document.get("license_references", [])
        if reference.get("spdx_license_key") in custom_licenses
    }
    for license_id in custom_licenses:
        references.setdefault(license_id, {
            "extractedText": "NOASSERTION",
            "licenseId": license_id,
            "name": license_id,
        })
    return licenses_by_file, references, comments_by_file


def debian_os_package(packages: list[dict[str, Any]], path: Path) -> dict[str, Any]:
    distros = {
        distro
        for package in packages
        for reference in package.get("externalRefs", [])
        if reference.get("referenceType") == "purl"
        for distro in parse_qs(urlsplit(reference["referenceLocator"]).query).get("distro", [])
    }
    if len(distros) != 1 or not next(iter(distros), "").startswith("debian-"):
        raise ValueError(f"{path}: packages must identify one Debian distro")
    version = next(iter(distros)).removeprefix("debian-")
    return {
        "SPDXID": f"SPDXRef-OperatingSystem-debian-{version}",
        "copyrightText": "NOASSERTION",
        "downloadLocation": "NONE",
        "filesAnalyzed": False,
        "licenseConcluded": "NOASSERTION",
        "licenseDeclared": "NOASSERTION",
        "name": "debian",
        "primaryPackagePurpose": "OPERATING-SYSTEM",
        "versionInfo": version,
    }


def set_document_namespace(document: dict[str, Any], extension_name: str, platform: str) -> None:
    # SPDX element IDs are scoped by namespace; hash the content to prevent
    # distinct SBOMs from sharing identities when consumers combine them.
    content = {key: value for key, value in document.items() if key != "documentNamespace"}
    digest = hashlib.sha256(
        json.dumps(content, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    document["documentNamespace"] = (
        "https://github.com/cnpg-extensions/postgres-extensions-containers/"
        f"sbom-generator/v1/documents/{extension_name}/{platform.replace('/', '-')}-{digest}"
    )


def compose(builder_document: dict[str, Any], *,
            extension_name: str,
            builder_path: Path = Path("builder"),
            scancode_report: dict[str, Any] | None = None,
            final_inventory: dict[str, Any] | list[dict[str, Any]] | None = None,
            platform: str | None = None,
            evidence: dict[str, Any] | None = None,
            ) -> dict[str, Any]:
    """Return one raw, platform-specific SPDX predicate.

    ``final_inventory`` is the normal path.  ``subject`` handling remains as a
    compatibility fixture for the original composer tests, but the generator
    never needs a final image/index digest before it writes its predicate.
    """

    builder = builder_predicate(builder_document, builder_path)
    licenses_by_file, custom_licenses, license_comments_by_file = scancode_licenses(
        scancode_report or {}
    )
    final = (
        final_inventory_files(final_inventory, builder_path)
        if final_inventory is not None
        else final_files(builder_document, builder_path)
    )
    builder_records = builder["files"]
    relationships = builder["relationships"]
    packages = builder["packages"]
    packages_without_file_analysis = {
        package["SPDXID"]
        for package in packages
        if package.get("filesAnalyzed") is False
    }

    builder_packages = {
        package["SPDXID"]: package
        for package in packages
        if package.get("primaryPackagePurpose") != "FILE"
    }

    all_package_ids = {package["SPDXID"] for package in packages}
    package_ids = set(builder_packages)
    package_ids_by_name: defaultdict[str, set[str]] = defaultdict(set)
    for package_id, package in builder_packages.items():
        if package_id not in packages_without_file_analysis:
            package_ids_by_name[package["name"]].add(package_id)
    retained_package_ids: set[str] = set()
    owners_by_source_file: defaultdict[str, set[str]] = defaultdict(set)
    for relationship in relationships:
        if relationship["relationshipType"] != "CONTAINS":
            continue
        package_id = relationship["spdxElementId"]
        source_file_id = relationship["relatedSpdxElement"]
        if package_id in package_ids and package_id not in packages_without_file_analysis:
            owners_by_source_file[source_file_id].add(package_id)

    by_checksum: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    all_file_ids = {record["SPDXID"] for record in builder_records}
    for record in builder_records:
        for checksum in record["checksums"]:
            by_checksum[checksum_key(
                checksum["algorithm"], checksum["checksumValue"]
            )].append(record)

    composed_files: list[dict[str, Any]] = []
    source_to_final: defaultdict[str, set[str]] = defaultdict(set)
    direct_final_owners: defaultdict[str, set[str]] = defaultdict(set)
    def add_final_file(record: dict[str, Any], owner: str | None = None) -> None:
        output_record = {
            "SPDXID": file_id(record["name"], record["algorithm"], record["value"]),
            "checksums": record.get("checksums", [{
                "algorithm": record["algorithm"].upper(),
                "checksumValue": record["value"],
            }]),
            "copyrightText": "NOASSERTION",
            "fileName": record["name"],
            "licenseConcluded": "NOASSERTION",
            "licenseInfoInFiles": ["NOASSERTION"],
        }
        composed_files.append(output_record)
        if owner is not None:
            retained_package_ids.add(owner)
            direct_final_owners[output_record["SPDXID"]].add(owner)

    for final_record in final:
        final_name = final_record["name"].lstrip("/")
        license_parts = final_name.split("/", 2)
        if license_parts[0] == "licenses" and len(license_parts) > 1:
            owners = package_ids_by_name.get(license_parts[1], set())
            add_final_file(final_record, next(iter(owners)) if len(owners) == 1 else None)
            continue

        candidates = by_checksum.get(
            checksum_key(final_record["algorithm"], final_record["value"]), []
        )
        if not candidates:
            add_final_file(final_record)
            continue

        owned_candidates = [
            record for record in candidates if record["SPDXID"] in owners_by_source_file
        ]
        candidates = owned_candidates or candidates
        best_score = max(path_score(record["fileName"], final_name) for record in candidates)
        selected = [
            record for record in candidates
            if path_score(record["fileName"], final_name) == best_score
        ]
        selected.sort(key=lambda record: record["SPDXID"])
        source_names = {record["fileName"].lstrip("/") for record in selected}
        if len(source_names) > 1:
            add_final_file(final_record)
            continue

        source = selected[0]
        new_id = file_id(final_record["name"], final_record["algorithm"], final_record["value"])
        output_record = source.copy()
        checksums_by_algorithm = {
            checksum["algorithm"].upper(): {
                "algorithm": checksum["algorithm"].upper(),
                "checksumValue": checksum["checksumValue"].lower(),
            }
            for checksum in source.get("checksums", [])
        }
        # Prefer hashes computed from the final payload, while retaining any
        # additional algorithms already supplied by the builder scan.
        checksums_by_algorithm.update({
            checksum["algorithm"].upper(): {
                "algorithm": checksum["algorithm"].upper(),
                "checksumValue": checksum["checksumValue"].lower(),
            }
            for checksum in final_record.get("checksums", [])
        })
        output_record["checksums"] = [
            checksums_by_algorithm[algorithm]
            for algorithm in sorted(checksums_by_algorithm)
        ]
        output_record["SPDXID"] = new_id
        output_record["fileName"] = final_record["name"]
        composed_files.append(output_record)
        for record in selected:
            source_to_final[record["SPDXID"]].add(new_id)

    for record in composed_files:
        source_path = record["fileName"].lstrip("/")
        licenses = licenses_by_file.get(source_path)
        if licenses:
            record["licenseInfoInFiles"] = sorted(
                set(record.get("licenseInfoInFiles", []))
                .union(licenses)
                - {"NONE", "NOASSERTION"}
            )
        comments = license_comments_by_file.get(source_path)
        if comments:
            existing_comment = record.get("licenseComments")
            comment_parts = ([existing_comment] if existing_comment else []) + sorted(set(comments))
            record["licenseComments"] = "\n".join(comment_parts)

    for source_file_id, package_ids_for_file in owners_by_source_file.items():
        final_ids_for_source = source_to_final.get(source_file_id)
        if not final_ids_for_source:
            continue
        retained_package_ids.update(package_ids_for_file)

    composed_relationships: list[dict[str, Any]] = []
    seen_relationships: set[str] = set()
    for relationship in relationships:
        element_id = relationship["spdxElementId"]
        related_id = relationship["relatedSpdxElement"]
        if (
            relationship["relationshipType"] == "CONTAINS"
            and element_id in packages_without_file_analysis
            and related_id in all_file_ids
        ):
            # SPDX forbids file ownership relationships for packages whose
            # file analysis is explicitly disabled.
            continue
        if (
            (element_id in all_file_ids and element_id not in source_to_final)
            or (related_id in all_file_ids and related_id not in source_to_final)
        ):
            continue
        if (
            (element_id in all_package_ids and element_id not in retained_package_ids)
            or (related_id in all_package_ids and related_id not in retained_package_ids)
        ):
            continue
        if element_id not in source_to_final and related_id not in source_to_final:
            composed_relationships.append(relationship.copy())
            continue

        element_ids = source_to_final.get(element_id, {element_id})
        related_ids = source_to_final.get(related_id, {related_id})
        for new_element_id in element_ids:
            for new_related_id in related_ids:
                replacement = relationship.copy()
                replacement["spdxElementId"] = new_element_id
                replacement["relatedSpdxElement"] = new_related_id
                identity = json.dumps(replacement, sort_keys=True, separators=(",", ":"))
                if identity not in seen_relationships:
                    seen_relationships.add(identity)
                    composed_relationships.append(replacement)

    composed_relationships.extend(
        {
            "spdxElementId": package_id,
            "relationshipType": "CONTAINS",
            "relatedSpdxElement": file_id_value,
        }
        for file_id_value, package_ids_for_file in direct_final_owners.items()
        for package_id in sorted(package_ids_for_file)
    )

    output = deepcopy(builder)
    os_package = debian_os_package(packages, builder_path)
    output["packages"] = [
        deepcopy(package) for package in packages
        if package["SPDXID"] in retained_package_ids
    ]
    output["packages"].append(os_package)
    output["files"] = composed_files
    output["relationships"] = composed_relationships
    package_by_id = {package["SPDXID"]: package for package in output["packages"]}
    file_by_id = {record["SPDXID"]: record for record in composed_files}
    licenses_by_package: defaultdict[str, set[str]] = defaultdict(set)
    for relationship in composed_relationships:
        package = package_by_id.get(relationship.get("spdxElementId"))
        file = file_by_id.get(relationship.get("relatedSpdxElement"))
        if (
            relationship.get("relationshipType") == "CONTAINS"
            and package is not None
            and file is not None
            and package.get("filesAnalyzed", True) is not False
        ):
            licenses_by_package[package["SPDXID"]].update(
                set(file.get("licenseInfoInFiles", [])) - {"NONE", "NOASSERTION"}
            )
    for package_id, licenses in licenses_by_package.items():
        if licenses:
            package = package_by_id[package_id]
            package["licenseInfoFromFiles"] = sorted(
                set(package.get("licenseInfoFromFiles", []))
                .union(licenses)
                - {"NONE", "NOASSERTION"}
            )
    for package in output["packages"]:
        if package.get("licenseDeclared") not in {None, "NONE", "NOASSERTION"}:
            continue
        file_licenses = set(package.get("licenseInfoFromFiles", [])) - {"NONE", "NOASSERTION"}
        if not file_licenses:
            continue
        package["licenseDeclared"] = " AND ".join(
            f"({term})" if LICENSE_OPERATOR.search(term) else term
            for term in sorted(file_licenses)
        )
    extracted = {
        item["licenseId"]: item
        for item in output.get("hasExtractedLicensingInfos", [])
    }
    for license_id in custom_licenses:
        extracted.setdefault(license_id, custom_licenses[license_id])
    output["hasExtractedLicensingInfos"] = [
        extracted[key] for key in sorted(extracted)
    ]
    described_ids = {
        relationship["relatedSpdxElement"]
        for relationship in composed_relationships
        if relationship.get("spdxElementId") == output["SPDXID"]
        and relationship.get("relationshipType") == "DESCRIBES"
    }
    for package_id in sorted(retained_package_ids):
        if package_id not in described_ids:
            output["relationships"].append({
                "spdxElementId": output["SPDXID"],
                "relationshipType": "DESCRIBES",
                "relatedSpdxElement": package_id,
            })
    output["relationships"].append({
        "spdxElementId": output["SPDXID"],
        "relationshipType": "DESCRIBES",
        "relatedSpdxElement": os_package["SPDXID"],
    })
    output["relationships"].extend(
        {
            "spdxElementId": os_package["SPDXID"],
            "relationshipType": "CONTAINS",
            "relatedSpdxElement": package["SPDXID"],
        }
        for package in output["packages"]
        if package["SPDXID"] != os_package["SPDXID"]
        and any(
            reference.get("referenceType") == "purl"
            and reference.get("referenceLocator", "").startswith("pkg:deb/debian/")
            for reference in package.get("externalRefs", [])
        )
    )
    output["name"] = f"{extension_name}-sbom"
    if platform is not None:
        if platform not in {"linux/amd64", "linux/arm64"}:
            raise ValueError(f"unsupported target platform: {platform!r}")
    creation_info = output.setdefault("creationInfo", {})
    creators = list(creation_info.get("creators", []))
    generator_version = os.getenv("SBOM_GENERATOR_REVISION") or "unknown"
    generator_creator = f"Tool: {GENERATOR_NAME}-{generator_version}"
    if generator_creator not in creators:
        creators.append(generator_creator)
    creation_info["creators"] = creators
    metadata = {
        "generator": GENERATOR_NAME,
        "generatorVersion": generator_version,
        "generatorRepository": GENERATOR_REPOSITORY,
        "platform": platform,
        "evidence": evidence or {},
    }
    output["annotations"] = list(output.get("annotations", [])) + [{
        "annotationDate": creation_info.get("created", "1970-01-01T00:00:00Z"),
        "annotationType": "OTHER",
        "annotator": generator_creator,
        "comment": json.dumps(metadata, sort_keys=True, separators=(",", ":")),
        "spdxElementId": "SPDXRef-DOCUMENT",
    }]
    if platform is not None:
        set_document_namespace(output, extension_name, platform)
    return output


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compose one platform-specific final-payload SPDX predicate"
    )
    parser.add_argument("--builder-sbom", type=Path, required=True)
    parser.add_argument("--final-inventory", type=Path, required=True)
    parser.add_argument("--platform", required=True)
    parser.add_argument(
        "--scancode-report",
        type=Path,
        help="Optional ScanCode JSON report for shipped license files",
    )
    parser.add_argument("--evidence", type=Path, help="Optional reproducibility evidence JSON")
    parser.add_argument("--extension-name", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    output = compose(
        read_json(args.builder_sbom),
        extension_name=args.extension_name,
        builder_path=args.builder_sbom,
        final_inventory=read_json(args.final_inventory),
        platform=args.platform,
        scancode_report=read_json(args.scancode_report) if args.scancode_report else {},
        evidence=read_json(args.evidence) if args.evidence else {},
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as stream:
        json.dump(output, stream, indent=2)
        stream.write("\n")
    print(
        f"composed {len(output['packages'])} packages, "
        f"{len(output['files'])} final files, "
        f"{len(output['relationships'])} relationships",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
