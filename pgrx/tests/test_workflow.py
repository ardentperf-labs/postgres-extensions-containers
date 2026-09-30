import sys
from pathlib import Path
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from workflow import boolean,select,changed_extensions

class SelectorTest(unittest.TestCase):
    inventory={'pg-session-jwt':{'versions':{'trixie':{'18':{}},'bookworm':{'18':{}}}},'pg-durable':{'versions':{'trixie':{'18':{}}}}}
    def test_native_default_and_hosted(self):
        self.assertFalse(boolean('false'))
        self.assertEqual(select({'extension_name':'pg-session-jwt'},self.inventory),['linux/amd64','linux/arm64'])
        inputs={'extension_name':'pg-session-jwt','local':'true','distro':'trixie','platform':'linux/amd64','local_run_id':'unique-case-1'}
        self.assertEqual(select(inputs,self.inventory),['linux/amd64'])
        for platform in ('','linux/arm64'):
            with self.assertRaises(ValueError):select({**inputs,'platform':platform},self.inventory)
        with self.assertRaises(ValueError):select({**inputs,'local':'false'},self.inventory)
    def test_final_requires_gate_and_bounded_case(self):
        inputs={'extension_name':'pg-session-jwt','local':True,'distro':'trixie','local_multiplatform':True,'local_run_id':'final-case-1'}
        with self.assertRaises(ValueError):select(inputs,self.inventory)
        inputs['native_gate_sha256']='a'*64
        self.assertEqual(select(inputs,self.inventory),['linux/amd64','linux/arm64'])
        with self.assertRaises(ValueError):select({**inputs,'extension_name':'pg-durable'},self.inventory)
    def test_paths(self):
        self.assertEqual(changed_extensions(['sbom-generator/generator.py'],self.inventory),[])
        self.assertEqual(changed_extensions(['pg-durable/Dockerfile'],self.inventory),['pg-durable'])
        self.assertEqual(changed_extensions(['pgrx/sbom/augment_spdx.py'],self.inventory),sorted(self.inventory))
