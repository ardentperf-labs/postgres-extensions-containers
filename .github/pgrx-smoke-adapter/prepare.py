#!/usr/bin/env python3
"""Build a hash-pinned ARM smoke overlay outside the signed source checkout."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

EXPECTED_COMMIT = 'f3d0af65b9e1a8fd97b1b364c94fe9a699f252a1'
EXPECTED_SMOKE_SHA256 = '545694af478f2b92306c0176d119ed570df6114ef543eee6cc2a0005b942d6a8'


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def replace_once(text, old, new, name):
    count = text.count(old)
    if count != 1:
        raise ValueError(f'{name}: expected one source match, found {count}')
    return text.replace(old, new, 1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--source-root', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()

    source_root = args.source_root.resolve()
    source = args.source.resolve()
    expected_source = (source_root / 'pgrx/smoke.py').resolve()
    if source != expected_source:
        raise ValueError('source must be the exact checkout pgrx/smoke.py')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source_root, text=True).strip()
    if commit != EXPECTED_COMMIT:
        raise ValueError('unexpected source checkout commit')
    status = subprocess.check_output(['git', 'status', '--porcelain'], cwd=source_root, text=True)
    if status:
        raise ValueError('source checkout is not pristine')
    original = source.read_bytes()
    if sha256(original) != EXPECTED_SMOKE_SHA256:
        raise ValueError('source smoke.py hash differs from reviewed baseline')
    text = original.decode('utf-8')

    text = replace_once(text, 'import os\nimport re\n',
                        'import os\nimport platform as host_platform\nimport re\n',
                        'native architecture import')
    text = replace_once(text,
        'def smoke(preparation, assembly, output, selector=None):\n    fixtures = ROOT / \'pgrx/dependencies/fixtures\'\n',
        "def smoke(preparation, assembly, output, selector=None):\n"
        "    runtime_platform = os.environ.get('PGRX_SMOKE_PLATFORM', 'linux/amd64')\n"
        "    architecture = {'linux/amd64': 'amd64', 'linux/arm64': 'arm64'}.get(runtime_platform)\n"
        "    if architecture is None:\n"
        "        raise ValueError('smoke platform must be linux/amd64 or linux/arm64')\n"
        "    machine_code = {'amd64': '62', 'arm64': '183'}[architecture]\n"
        "    def normalize_arch(value):\n"
        "        return {'x86_64': 'amd64', 'amd64': 'amd64', 'aarch64': 'arm64', 'arm64': 'arm64'}.get(value)\n"
        "    host_architecture = normalize_arch(host_platform.machine())\n"
        "    docker_architecture = normalize_arch(subprocess.check_output(\n"
        "        ['docker', 'info', '--format', '{{.Architecture}}'], text=True).strip())\n"
        "    if host_architecture != architecture or docker_architecture != architecture:\n"
        "        raise ValueError('smoke runner and Docker daemon must be native ' + architecture)\n"
        "    fixtures = ROOT / 'pgrx/dependencies/fixtures'\n",
        'runtime architecture checks')
    replacements = [
        ("kind_pin = pins['tools']['kind']['platforms']['amd64']",
         "kind_pin = pins['tools']['kind']['platforms'][architecture]", 'Kind platform pin'),
        ("['docker', 'create', '--platform', 'linux/amd64',",
         "['docker', 'create', '--platform', runtime_platform,", 'kubectl platform'),
        ("if node['status']['nodeInfo']['architecture'] != 'amd64':\n            raise ValueError('smoke node is not native amd64')",
         "if node['status']['nodeInfo']['architecture'] != architecture:\n            raise ValueError('smoke node architecture does not match ' + architecture)",
         'Kubernetes node architecture'),
        ("child = graph['platforms']['linux/amd64']",
         "child = graph['platforms'][runtime_platform]", 'image child platform'),
        ("if machine != '62':\n                raise ValueError('mounted ELF is not amd64')",
         "if machine != machine_code:\n                raise ValueError('mounted ELF architecture does not match ' + architecture)",
         'mounted ELF architecture'),
        ("'platform': 'linux/amd64',\n            'runnable_digest'",
         "'platform': runtime_platform,\n            'runner_architecture': host_architecture, 'docker_architecture': docker_architecture,\n            'runnable_digest'",
         'runtime evidence platform'),
    ]
    for old, new, name in replacements:
        text = replace_once(text, old, new, name)

    args.output.mkdir(parents=True, exist_ok=False)
    overlay_smoke = args.output / 'smoke.py'
    overlay_smoke.write_text(text, encoding='utf-8')
    adapter_root = Path(__file__).resolve().parent
    components = {}
    for name in ('prepare.py', 'run.py'):
        path = adapter_root / name
        components[name] = sha256(path.read_bytes())
    components['source_smoke.py'] = EXPECTED_SMOKE_SHA256
    components['overlay_smoke.py'] = sha256(overlay_smoke.read_bytes())
    bundle = hashlib.sha256()
    for name, digest in sorted(components.items()):
        bundle.update(name.encode() + b'\0' + digest.encode() + b'\n')
    manifest = {
        'source_commit': commit,
        'source_smoke_sha256': EXPECTED_SMOKE_SHA256,
        'overlay_smoke_sha256': components['overlay_smoke.py'],
        'adapter_components': components,
        'adapter_bundle_sha256': bundle.hexdigest(),
        'platform': 'linux/arm64',
    }
    (args.output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
