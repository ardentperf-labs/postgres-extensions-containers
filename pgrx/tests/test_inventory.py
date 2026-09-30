"""Compatibility inventory: production discovery must cover every restored recipe."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
EXPECTED = {
    'pg-durable': 'v0.2.7', 'pg-graphql': 'v1.6.2',
    'pg-jsonschema': 'v0.3.4', 'pg-parquet': 'v0.5.1',
    'pg-search': 'v0.25.6', 'pg-session-jwt': 'v0.5.0',
}

class InventoryTest(unittest.TestCase):
    def test_complete_inventory(self):
        discovered = {p.parent.name for p in ROOT.glob('*/metadata.hcl')
                      if re.search(r'build_system\s*=\s*"pgrx"', p.read_text())}
        self.assertEqual(discovered, set(EXPECTED))

    def test_versions_targets_and_build_attribution(self):
        for name, version in EXPECTED.items():
            with self.subTest(extension=name):
                metadata = (ROOT / name / 'metadata.hcl').read_text()
                self.assertEqual(re.findall(r'package\s*=\s*"([^"]+)"', metadata), [version] * 2)
                self.assertEqual(re.findall(r'sql\s*=\s*"([^"]+)"', metadata), [version[1:]] * 2)
                self.assertEqual(re.findall(r'"(\d+)"\s*=\s*{', metadata), ['18'] * 2)
                self.assertRegex(metadata, r'bookworm\s*=')
                self.assertRegex(metadata, r'trixie\s*=')
                recipe = (ROOT / name / 'Dockerfile').read_text()
                self.assertRegex(recipe, r'# https://github.com/[^\n]+/(?:blob|issues)/[^\n]+\nRUN (?:cd pg_search && )?cargo pgrx|# Upstream package command: https://github.com/[^\n]+/blob/[^\n]+\nRUN cargo pgrx')
                self.assertIn('COPY pgrx/ /pgrx/', recipe)
                self.assertIn('/pgrx/install-pgrx-build-environment.sh', recipe)
