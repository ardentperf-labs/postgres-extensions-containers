#!/usr/bin/env python3
import hashlib
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1]))

from spdx_validation import validate_spdx_document  # noqa: E402


def document(file_checksums):
    return {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": "validation-test",
        "documentNamespace": "https://spdx.org/spdxdocs/validation-test-1",
        "creationInfo": {
            "created": "2026-09-30T00:00:00Z",
            "creators": ["Tool: validation-test"],
        },
        "files": [{
            "SPDXID": "SPDXRef-File-payload",
            "fileName": "payload",
            "checksums": file_checksums,
            "licenseConcluded": "NOASSERTION",
            "licenseInfoInFiles": ["NOASSERTION"],
            "copyrightText": "NOASSERTION",
        }],
        "packages": [],
        "relationships": [{
            "spdxElementId": "SPDXRef-DOCUMENT",
            "relationshipType": "DESCRIBES",
            "relatedSpdxElement": "SPDXRef-File-payload",
        }],
    }


class SpdxValidationTest(unittest.TestCase):
    def setUp(self):
        contents = b"payload"
        self.checksums = [
            {"algorithm": "SHA1", "checksumValue": hashlib.sha1(contents).hexdigest()},
            {"algorithm": "SHA256", "checksumValue": hashlib.sha256(contents).hexdigest()},
        ]

    def test_valid_spdx_document_has_no_findings(self):
        self.assertEqual(validate_spdx_document(document(self.checksums)), [])

    def test_missing_sha1_is_reported(self):
        findings = validate_spdx_document(document(self.checksums[1:]))
        self.assertEqual(len(findings), 1)
        self.assertIn("SHA1", findings[0])

    def test_hook_structural_errors_are_reported_by_full_validator(self):
        cases = []
        missing_relation = document(self.checksums)
        missing_relation["relationships"][0]["relatedSpdxElement"] = "SPDXRef-missing"
        cases.append(missing_relation)
        missing_license = document(self.checksums)
        missing_license["files"][0]["licenseInfoInFiles"] = ["LicenseRef-missing"]
        cases.append(missing_license)
        malformed_hash = document([{"algorithm": "SHA1", "checksumValue": "invalid"},
                                   {"algorithm": "SHA256", "checksumValue": "invalid"}])
        cases.append(malformed_hash)
        for broken in cases:
            with self.subTest(document=broken):
                self.assertTrue(validate_spdx_document(broken))


if __name__ == "__main__":
    unittest.main()
