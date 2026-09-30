import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'pgrx' / 'sbom'))
from augment_spdx import augment_spdx,license_expression


def digest(data):
    return hashlib.sha256(data).hexdigest()

class HookTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.builder = self.root / 'builder'
        self.final = self.root / 'final'
        self.builder.mkdir(); self.final.mkdir()
        self.evidence = self.builder / 'build/pgrx-sbom'
        self.evidence.mkdir(parents=True)
        elf = bytearray(64); elf[:6] = b'\x7fELF\x02\x01'; elf[18:20] = (62).to_bytes(2, 'little')
        for base, path in [(self.builder, 'build/demo.so'), (self.final, 'lib/demo.so')]:
            file = base / path; file.parent.mkdir(parents=True, exist_ok=True); file.write_bytes(elf)
        (self.builder / 'build/Cargo.lock').write_text('locked\n')
        self.metadata = {'version': 1, 'packages': [
            {'id': name, 'name': name, 'version': '1.0', 'source': 'registry+https://github.com/rust-lang/crates.io-index', 'license': 'MIT', 'targets': [{'kind': ['lib']}]}
            for name in ['demo', 'runtime', 'build-tool', 'dev-tool', 'unused']],
            'resolve': {'root': 'demo', 'nodes': [
                {'id': 'demo', 'features': ['pg18'], 'deps': [
                    {'pkg': 'runtime', 'dep_kinds': [{'kind': None, 'target': None}]},
                    {'pkg': 'build-tool', 'dep_kinds': [{'kind': 'build', 'target': None}]},
                    {'pkg': 'dev-tool', 'dep_kinds': [{'kind': 'dev', 'target': None}]}]},
                *[{'id': name, 'features': [], 'deps': []} for name in ['runtime', 'build-tool', 'dev-tool', 'unused']]]}}
        self.manifest = {'schema_version': 1, 'identity': {'extension': 'pg-demo', 'sql_name': 'demo', 'source_version': 'v1.0', 'sql_version': '1.0', 'repository': 'example/demo', 'revision': 'a'*40, 'archive_sha256': 'b'*64},
            'target': {'platform': 'linux/amd64', 'rust_target': 'x86_64-unknown-linux-gnu', 'pg_major': '18', 'distro': 'trixie'},
            'build': {'root_id': 'demo', 'manifest': 'Cargo.toml', 'features': ['pg18'], 'default_features': False, 'profile': 'release', 'rustflags': '', 'tools': {'rustc': 'fixture'}},
            'inputs': {'lock_sha256': digest(b'locked\n'), 'timestamp': '2026-01-01T00:00:00Z'},
            'reports': {}, 'licenses': [],
            'payload': [{'builder': 'build/demo.so', 'final': 'lib/demo.so', 'kind': 'library', 'sha256': digest(elf)}]}
        self.write_report('cargo-metadata', self.metadata)
        self.manifest['build']['target_cfg'] = ['target_arch="x86_64"', 'target_os="linux"', 'target_env="gnu"', 'target_pointer_width="64"']
        self.write_report('cyclonedx', {'bomFormat': 'CycloneDX', 'specVersion': '1.5', 'metadata': {'component': {'bom-ref':'demo','name':'demo','version':'1.0'}, 'properties': [{'name':'cdx:rustc:sbom:target:triple','value':'x86_64-unknown-linux-gnu'}]}, 'components': [{'bom-ref':'runtime','name':'runtime','version':'1.0'}]})
        license_text='MIT fixture license text'
        path=self.final/'licenses/rust/license.txt';path.parent.mkdir(parents=True);path.write_text(license_text)
        self.manifest['licenses']=[{'cargo_id':key,'name':'MIT','final':'licenses/rust/license.txt','sha256':digest(license_text.encode())} for key in ('demo','runtime')]
        self.write_report('cargo-about', {'licenses': [{'id':'MIT','text':license_text,'used_by':[{'crate':{'id':key}} for key in ('demo','runtime')]}], 'crates': []})
        self.document = {'SPDXID': 'SPDXRef-DOCUMENT', 'spdxVersion': 'SPDX-2.3', 'creationInfo': {'created': '2026-01-01T00:00:00Z', 'creators': ['Tool: generator']},
            'packages': [{'SPDXID': 'SPDXRef-Package-extension-payload', 'name': 'payload'}, {'SPDXID': 'SPDXRef-OS', 'name': 'debian'}],
            'files': [{'SPDXID': 'SPDXRef-file', 'fileName': 'lib/demo.so', 'checksums': [{'algorithm': 'SHA256', 'checksumValue': digest(elf)}]}],
            'relationships': [
                {'spdxElementId': 'SPDXRef-DOCUMENT', 'relationshipType': 'DESCRIBES', 'relatedSpdxElement': 'SPDXRef-Package-extension-payload'},
                {'spdxElementId': 'SPDXRef-OS', 'relationshipType': 'CONTAINS', 'relatedSpdxElement': 'SPDXRef-file'},
                {'spdxElementId': 'SPDXRef-Package-extension-payload', 'relationshipType': 'CONTAINS', 'relatedSpdxElement': 'SPDXRef-file'},
            ]}
        self.context = SimpleNamespace(api_version=1, extension_name='extension', platform='linux/amd64', builder_path=self.builder, final_path=self.final, builder_document={'packages': [{'name': 'build-only'}]})

    def write_report(self, name, value):
        data = json.dumps(value).encode(); (self.evidence / (name+'.json')).write_bytes(data)
        self.manifest['reports'][name] = {'path': name+'.json', 'sha256': digest(data), 'tool_version': 'fixture'}

    def run_hook(self):
        (self.evidence / 'manifest.json').write_text(json.dumps(self.manifest))
        return augment_spdx(self.document, self.context)

    def test_preserves_generator_and_selects_runtime_graph(self):
        before = copy.deepcopy(self.document); builder = copy.deepcopy(self.context.builder_document)
        result = self.run_hook()
        self.assertEqual(self.document, before); self.assertEqual(self.context.builder_document, builder)
        self.assertEqual({p['name'] for p in result['packages']}, {'demo','runtime','debian'})
        self.assertEqual(result['files'], before['files'])
        self.assertNotIn(before['relationships'][0], result['relationships'])
        self.assertIn(before['relationships'][1], result['relationships'])
        self.assertNotIn(before['relationships'][2], result['relationships'])
        self.assertEqual(result['creationInfo'], before['creationInfo'])
        self.assertEqual(result, self.run_hook())

    def test_root_crate_describes_extension_without_adopting_legacy_payload_license(self):
        legacy_payload = self.document['packages'][0]
        legacy_payload.update(licenseDeclared='Apache-2.0 AND MIT',
                              licenseInfoFromFiles=['Apache-2.0', 'MIT'])
        result = self.run_hook()
        by_name = {package['name']: package for package in result['packages']}
        root = by_name['demo']
        self.assertEqual(root['licenseDeclared'], 'MIT')
        self.assertFalse(root['filesAnalyzed'])
        self.assertNotIn('licenseInfoFromFiles', root)
        self.assertNotIn('payload', by_name)
        self.assertNotIn(legacy_payload['SPDXID'], {p['SPDXID'] for p in result['packages']})
        self.assertNotIn({'spdxElementId': 'SPDXRef-DOCUMENT', 'relationshipType': 'DESCRIBES',
                          'relatedSpdxElement': legacy_payload['SPDXID']}, result['relationships'])
        self.assertIn({'spdxElementId': 'SPDXRef-DOCUMENT', 'relationshipType': 'DESCRIBES',
                       'relatedSpdxElement': root['SPDXID']}, result['relationships'])
        self.assertIn({'spdxElementId': root['SPDXID'], 'relationshipType': 'DEPENDS_ON',
                       'relatedSpdxElement': by_name['runtime']['SPDXID']}, result['relationships'])
        self.assertFalse(any(r['spdxElementId'] == root['SPDXID'] and
                             r['relationshipType'] == 'CONTAINS' for r in result['relationships']))
        self.assertIn(self.document['files'][0], result['files'])

    def test_only_reserved_legacy_package_is_removed(self):
        other = {'SPDXID': 'SPDXRef-other-payload', 'name': 'extension-extension-artifacts',
                 'filesAnalyzed': False, 'downloadLocation': 'NOASSERTION', 'copyrightText': 'NOASSERTION'}
        self.document['packages'].append(other)
        result = self.run_hook()
        self.assertIn(other, result['packages'])

    def test_fresh_generator_without_synthetic_package_is_supported(self):
        self.document['packages'] = [self.document['packages'][1]]
        self.document['relationships'] = [self.document['relationships'][1]]
        result = self.run_hook()
        self.assertFalse(any(p['SPDXID'] == 'SPDXRef-Package-extension-payload'
                             for p in result['packages']))
        self.assertIn(self.document['files'][0], result['files'])
        self.assertTrue(any(r['spdxElementId'] == 'SPDXRef-DOCUMENT'
                            and r['relationshipType'] == 'DESCRIBES'
                            and r['relatedSpdxElement'].startswith('SPDXRef-Cargo-')
                            for r in result['relationships']))
        self.assertFalse(any(r.get('spdxElementId', '').startswith('SPDXRef-Cargo-')
                             and r.get('relationshipType') == 'CONTAINS'
                             for r in result['relationships']))

    def test_invalid_evidence_fails_closed(self):
        for group,key,value in [('target','platform','linux/arm64'), ('identity','extension','wrong'), ('inputs','lock_sha256','0'*64)]:
            with self.subTest(key=key):
                old=self.manifest[group][key]; self.manifest[group][key]=value
                if key=='extension': self.context.extension_name='pg-demo'
                with self.assertRaises(ValueError): self.run_hook()
                self.manifest[group][key]=old; self.context.extension_name='extension'
        self.context.api_version=2
        with self.assertRaises(ValueError): self.run_hook()

    def test_corrupt_report_and_path_escape(self):
        (self.evidence/'cyclonedx.json').write_text('{}')
        with self.assertRaisesRegex(ValueError,'hash'): self.run_hook()
        self.write_report('cyclonedx',{'bomFormat':'CycloneDX','specVersion':'1.5'})
        self.manifest['reports']['cyclonedx']['path']='../Cargo.lock'
        with self.assertRaises(ValueError): self.run_hook()

    def test_wrong_elf_and_missing_payload(self):
        (self.final/'lib/demo.so').write_bytes(b'wrong')
        with self.assertRaises(ValueError): self.run_hook()
        (self.final/'lib/demo.so').unlink()
        with self.assertRaises(ValueError): self.run_hook()

    def test_symlink_escape(self):
        (self.final/'lib/demo.so').unlink()
        (self.final/'lib/demo.so').symlink_to(self.builder/'build/demo.so')
        with self.assertRaises(ValueError): self.run_hook()

    def test_duplicate_json_keys(self):
        (self.evidence/'manifest.json').write_text('{"schema_version":1,"schema_version":2}')
        with self.assertRaises(ValueError): augment_spdx(self.document,self.context)

    def test_generator_hook_loader(self):
        sys.path.insert(0,str(ROOT/'sbom-generator'))
        from hooks import run_augmentation_hook
        hook=self.builder/'usr/local/share/cnpg-sbom/augment_spdx.py'
        hook.parent.mkdir(parents=True); hook.write_bytes((ROOT/'pgrx/sbom/augment_spdx.py').read_bytes())
        expected=self.run_hook()
        self.assertEqual(run_augmentation_hook(self.document,self.context),expected)

    def test_spdx_expressions_and_unknown_names(self):
        expression='(MIT OR Apache-2.0) AND GPL-2.0-only WITH Classpath-exception-2.0'
        self.assertEqual(license_expression(expression),expression)
        self.assertEqual(license_expression('Unknown License Name'),'NOASSERTION')
        self.assertEqual(license_expression('MIT AND'),'NOASSERTION')

    def test_missing_or_wrong_license_association(self):
        self.manifest['licenses'].pop()
        with self.assertRaisesRegex(ValueError,'missing shipped license'):self.run_hook()

    def test_proc_macro_and_distinct_sources(self):
        from augment_spdx import selected_graph,cargo_purl
        metadata=copy.deepcopy(self.metadata)
        metadata['packages'].append({'id':'macro','name':'macro','version':'1','targets':[{'kind':['proc-macro']},{'kind':['test']},{'kind':['custom-build']}]})
        metadata['resolve']['nodes'].append({'id':'macro','features':[],'deps':[]})
        metadata['resolve']['nodes'][0]['deps'].append({'pkg':'macro','dep_kinds':[{'kind':None,'target':None}]})
        selected,_=selected_graph(metadata,'demo')
        self.assertNotIn('macro',selected)
        a={'name':'same','version':'1.0','source':'registry+https://github.com/rust-lang/crates.io-index'}
        b={**a,'source':'git+https://example.test/repo#'+'a'*40}
        self.assertNotEqual(cargo_purl(a,'a'*40),cargo_purl(b,'a'*40))
        a.update(source=None,manifest_path='/build/one/Cargo.toml')
        b.update(source=None,manifest_path='/build/two/Cargo.toml')
        self.assertNotEqual(cargo_purl(a,'a'*40),cargo_purl(b,'a'*40))
        b['manifest_path']='/outside/Cargo.toml'
        with self.assertRaises(ValueError):cargo_purl(b,'a'*40)

    def test_matching_existing_package_merges(self):
        self.document['packages'].append({'SPDXID':'SPDXRef-existing-runtime','name':'runtime','licenseConcluded':'MIT',
            'externalRefs':[{'referenceType':'purl','referenceLocator':'pkg:cargo/runtime@1.0'}]})
        result=self.run_hook()
        matches=[p for p in result['packages'] if p['name']=='runtime']
        self.assertEqual(len(matches),1);self.assertEqual(matches[0]['SPDXID'],'SPDXRef-existing-runtime')
        self.assertEqual(matches[0]['licenseConcluded'],'MIT')

    def test_arm_evidence_as_data(self):
        self.manifest['target'].update(platform='linux/arm64',rust_target='aarch64-unknown-linux-gnu')
        self.manifest['build']['target_cfg'][0] = 'target_arch="aarch64"'
        self.context.platform='linux/arm64'
        cyclone=json.loads((self.evidence/'cyclonedx.json').read_text())
        cyclone['metadata']['properties'][0]['value']='aarch64-unknown-linux-gnu';self.write_report('cyclonedx',cyclone)
        data=bytearray((self.final/'lib/demo.so').read_bytes());data[18:20]=(183).to_bytes(2,'little')
        (self.final/'lib/demo.so').write_bytes(data);(self.builder/'build/demo.so').write_bytes(data)
        self.manifest['payload'][0]['sha256']=digest(data)
        self.document['files'][0]['checksums'][0]['checksumValue']=digest(data)
        self.assertTrue(self.run_hook()['packages'])
        self.manifest['target']['rust_target']='x86_64-unknown-linux-gnu'
        with self.assertRaisesRegex(ValueError,'Rust target'):self.run_hook()

    def test_wrong_cyclonedx_identity_and_feature_policy(self):
        self.manifest['build']['default_features']=True
        with self.assertRaisesRegex(ValueError,'default feature'):self.run_hook()
        self.manifest['build']['default_features']=False
        cyclone=json.loads((self.evidence/'cyclonedx.json').read_text());cyclone['metadata']['component']['bom-ref']='other'
        self.write_report('cyclonedx',cyclone)
        with self.assertRaisesRegex(ValueError,'CycloneDX root'):self.run_hook()

    def test_missing_evidence_and_unsupported_schema(self):
        from augment_spdx import augment_spdx
        with self.assertRaises(ValueError):augment_spdx(self.document,self.context)
        self.manifest['schema_version']=2
        with self.assertRaisesRegex(ValueError,'schema'):self.run_hook()
