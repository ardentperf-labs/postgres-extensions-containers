#!/usr/bin/env python3
"""Check one hosted SPDX document against the exact exported scratch image."""

import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import PurePosixPath
import re
import tarfile
from pathlib import Path


def require(ok, message):
    if not ok:
        raise ValueError(message)


def normalize(name):
    path = PurePosixPath(name)
    return str(PurePosixPath(*[part for part in path.parts if part not in ("/", ".")]))


def checksum_member(archive, member):
    if member.issym():
        data = member.linkname.encode()
        return {"SHA1": hashlib.sha1(data).hexdigest(), "SHA256": hashlib.sha256(data).hexdigest()}
    stream = archive.extractfile(member)
    require(stream is not None, f"cannot read exported image entry: {member.name}")
    sha1, sha256 = hashlib.sha1(), hashlib.sha256()
    while True:
        chunk = stream.read(1024 * 1024)
        if not chunk:
            break
        sha1.update(chunk)
        sha256.update(chunk)
    return {"SHA1": sha1.hexdigest(), "SHA256": sha256.hexdigest()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sbom", type=Path, required=True)
    parser.add_argument("--rootfs-tar", type=Path, required=True)
    parser.add_argument("--extension", required=True)
    parser.add_argument("--distro", required=True, choices=("bookworm", "trixie"))
    parser.add_argument("--arch", required=True, choices=("amd64", "arm64"))
    parser.add_argument("--image", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    document = json.loads(args.sbom.read_text())
    if "predicate" in document:
        document = document["predicate"]
    require(document.get("spdxVersion") == "SPDX-2.3", "SBOM is not SPDX 2.3")
    require(isinstance(document.get("files"), list), "SPDX document has no files array")
    require(isinstance(document.get("packages"), list), "SPDX document has no packages array")

    packages = {package["SPDXID"]: package for package in document["packages"]}
    file_by_id = {record["SPDXID"]: record for record in document["files"]}
    owners = defaultdict(set)
    for relationship in document.get("relationships", []):
        if (relationship.get("relationshipType") == "CONTAINS"
                and relationship.get("relatedSpdxElement") in file_by_id
                and relationship.get("spdxElementId") in packages):
            owners[relationship["relatedSpdxElement"]].add(relationship["spdxElementId"])

    with tarfile.open(args.rootfs_tar, "r:*") as archive:
        members = {
            normalize(member.name): member
            for member in archive.getmembers()
            if member.isfile() or member.issym()
        }
        seen = set()
        failures = []
        notice_rows = []
        for record in document["files"]:
            filename = normalize(record["fileName"])
            member = members.get(filename)
            if member is None:
                failures.append(f"SPDX file missing from image: {filename}")
                continue
            seen.add(filename)
            actual = checksum_member(archive, member)
            expected = {
                item["algorithm"].upper(): item["checksumValue"].lower()
                for item in record.get("checksums", [])
            }
            if not expected.get("SHA256"):
                failures.append(f"SPDX SHA256 missing: {filename}")
            for algorithm, value in expected.items():
                if algorithm in actual and actual[algorithm] != value:
                    failures.append(f"{algorithm} mismatch: {filename}")
            if filename.startswith("licenses/"):
                ids = sorted(owners.get(record["SPDXID"], set()))
                names = sorted(packages[item]["name"] for item in ids)
                sha256 = actual["SHA256"]
                notice_rows.append({
                    "path": filename,
                    "sha256": sha256,
                    "owner_ids": ids,
                    "owner_names": names,
                    "license_info_in_file": record.get("licenseInfoInFiles", []),
                })

        extra = sorted(set(members) - seen)
        if extra:
            failures.append(f"image files missing SPDX records: {len(extra)}")
        if args.extension in ("plr", "pgsphere"):
            gcc_rows = [
                row for row in notice_rows
                if re.fullmatch(r"gcc-[0-9]+-base", PurePosixPath(row["path"]).parent.name)
                and PurePosixPath(row["path"]).name == "copyright"
            ]
            if not gcc_rows:
                failures.append("expected GCC base copyright notice is absent")
            for row in gcc_rows:
                expected_owner = PurePosixPath(row["path"]).parent.name
                if row["owner_names"] != [expected_owner]:
                    failures.append(
                        f"GCC copyright owner mismatch for {row['path']}: {row['owner_names']}"
                    )

        duplicate_hashes = defaultdict(list)
        for row in notice_rows:
            duplicate_hashes[row["sha256"]].append(row)
        duplicate_notice_groups = [
            rows for rows in duplicate_hashes.values() if len(rows) > 1
        ]

    result = {
        "extension": args.extension,
        "distro": args.distro,
        "architecture": args.arch,
        "image": args.image,
        "spdx_version": document["spdxVersion"],
        "packages": len(document["packages"]),
        "debian_packages": sum(
            reference.get("referenceLocator", "").startswith("pkg:deb/")
            for package in document["packages"]
            for reference in package.get("externalRefs", [])
        ),
        "files": len(document["files"]),
        "files_checked_against_image": len(seen),
        "unassigned_files": sum(not owners.get(record["SPDXID"]) for record in document["files"]),
        "shipped_notice_files": len(notice_rows),
        "shipped_notice_files_with_package_owner": sum(bool(row["owner_names"]) for row in notice_rows),
        "notice_owners": notice_rows,
        "identical_notice_hash_groups": duplicate_notice_groups,
        "failures": failures,
    }
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    if failures:
        raise SystemExit("; ".join(failures))
    print(json.dumps({key: result[key] for key in (
        "extension", "distro", "architecture", "files", "shipped_notice_files",
        "shipped_notice_files_with_package_owner",
    )}))


if __name__ == "__main__":
    main()
