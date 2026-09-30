#!/usr/bin/env python3
"""Fast suites must be nonempty and never silently skip generator compatibility."""
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
suite=unittest.TestSuite()
for directory in ['sbom-generator/tests','pgrx/tests']:
    tests=unittest.TestLoader().discover(str(ROOT/directory),pattern='test_*.py')
    if not tests.countTestCases():raise RuntimeError('empty test discovery: '+directory)
    suite.addTests(tests)
result=unittest.TextTestRunner(verbosity=2).run(suite)
raise SystemExit(not result.wasSuccessful())
