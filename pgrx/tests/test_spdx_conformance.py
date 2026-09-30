"""Validate the real composer/hook boundary with the independent SPDX library."""

import json
from pathlib import Path
import sys
import unittest

from spdx_tools.spdx.parser.json.json_parser import parse_from_file
from spdx_tools.spdx.validation.document_validator import validate_full_spdx_document

import test_hook

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'sbom-generator'))
from compose import compose
from generator import final_inventory


class SPDXConformanceTest(unittest.TestCase):
    def test_composed_pgrx_document_conforms_to_spdx(self):
        fixture = test_hook.HookTest()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        builder = {
            'SPDXID': 'SPDXRef-DOCUMENT',
            'spdxVersion': 'SPDX-2.3',
            'dataLicense': 'CC0-1.0',
            'name': 'builder-evidence',
            'documentNamespace': 'https://example.test/spdx/builder',
            'creationInfo': {
                'created': '2026-01-01T00:00:00Z',
                'creators': ['Tool: integration-fixture'],
            },
            'packages': [{
                'SPDXID': 'SPDXRef-builder-debian',
                'name': 'base-files',
                'downloadLocation': 'NOASSERTION',
                'filesAnalyzed': False,
                'externalRefs': [{
                    'referenceCategory': 'PACKAGE-MANAGER',
                    'referenceType': 'purl',
                    'referenceLocator': 'pkg:deb/debian/base-files@13?distro=debian-13',
                }],
            }],
            'files': [],
            'relationships': [],
        }
        fixture.document = compose(
            builder,
            extension_name='pg-demo',
            builder_path=fixture.builder,
            final_inventory=final_inventory(fixture.final),
            platform='linux/amd64',
        )
        fixture.context.builder_document = builder
        output = fixture.run_hook()
        path = fixture.root / 'pgrx.spdx.json'
        path.write_text(json.dumps(output))
        findings = validate_full_spdx_document(parse_from_file(str(path)))
        self.assertEqual([], findings, '\n'.join(str(finding) for finding in findings))
        self.assertIn('runtime', {package['name'] for package in output['packages']})
        self.assertTrue(any(
            annotation.get('annotator') == 'Tool: cnpg-pgrx-hook-v1'
            for annotation in output['annotations']
        ))
