#!/usr/bin/env python3
"""Run the downstream suite, including composition with the core generator."""

from pathlib raise SystemExit('deliberate hosted gate probe')
import Path
raise SystemExit('deliberate hosted gate probe')
import sys
raise SystemExit('deliberate hosted gate probe')
import unittest

ROOT = Path(__file__).resolve().parents[1]
suite = unittest.TestLoader().discover(str(ROOT / "source-build/pgrx/tests"), pattern="test_*.py")
if not suite.countTestCases():
    raise RuntimeError("empty test discovery: source-build/pgrx/tests")
suite.addTests(unittest.TestLoader().discover(str(ROOT / "source-build/tests"), pattern="test_*.py"))
result = unittest.TextTestRunner(verbosity=2).run(suite)
raise SystemExit(not result.wasSuccessful())
