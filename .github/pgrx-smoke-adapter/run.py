#!/usr/bin/env python3
"""Invoke the exact downstream verifier with a separate native ARM smoke overlay."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import traceback

EXPECTED_COMMIT = 'f3d0af65b9e1a8fd97b1b364c94fe9a699f252a1'
EXPECTED_SOURCE_SMOKE_SHA256 = '545694af478f2b92306c0176d119ed570df6114ef543eee6cc2a0005b942d6a8'


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('stage', choices=['smoke'])
    parser.add_argument('--preparation', required=True, type=Path)
    parser.add_argument('--assembly', required=True, type=Path)
    parser.add_argument('--expected-extension', required=True)
    parser.add_argument('--expected-target', required=True)
    parser.add_argument('--expected-run-id', required=True)
    parser.add_argument('--cnpg-version')
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()

    source_root = Path(os.environ['PGRX_SOURCE_ROOT']).resolve()
    overlay = Path(os.environ['PGRX_SMOKE_OVERLAY']).resolve()
    output = args.output.resolve()
    if source_root == overlay or source_root in overlay.parents:
        raise ValueError('smoke overlay must remain outside the signed source checkout')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source_root, text=True).strip()
    if commit != EXPECTED_COMMIT:
        raise ValueError('unexpected exact-source checkout commit')
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=source_root, text=True):
        raise ValueError('exact-source checkout changed before verification')
    preparation = json.loads((args.preparation / 'preparation.json').read_text())
    if preparation.get('git_sha') != EXPECTED_COMMIT:
        raise ValueError('prepared source commit differs from exact checkout')
    assembly = json.loads((args.assembly / 'assembly.json').read_text())
    if preparation.get('extension') != args.expected_extension or assembly.get('extension') != args.expected_extension:
        raise ValueError('prepared or assembled extension differs from replay case')
    if assembly.get('target') != args.expected_target:
        raise ValueError('assembled target differs from replay case')
    if preparation.get('run_id') != args.expected_run_id or assembly.get('run_id') != args.expected_run_id:
        raise ValueError('artifact build run differs from replay case')
    source_smoke = source_root / 'pgrx/smoke.py'
    if sha256(source_smoke.read_bytes()) != EXPECTED_SOURCE_SMOKE_SHA256:
        raise ValueError('exact source smoke.py hash mismatch')
    manifest = json.loads((overlay / 'manifest.json').read_text())
    overlay_smoke = overlay / 'smoke.py'
    if manifest.get('source_commit') != EXPECTED_COMMIT:
        raise ValueError('adapter was prepared for a different source commit')
    if sha256(overlay_smoke.read_bytes()) != manifest.get('overlay_smoke_sha256'):
        raise ValueError('external smoke overlay hash mismatch')
    if os.environ.get('PGRX_SMOKE_PLATFORM') != 'linux/arm64' or manifest.get('platform') != 'linux/arm64':
        raise ValueError('this adapter is restricted to the native ARM64 smoke path')
    if platform.machine().lower() not in ('aarch64', 'arm64'):
        raise ValueError('runner is not native ARM64')

    adapter_root = Path(__file__).resolve().parent
    expected_components = {
        'prepare.py': sha256((adapter_root / 'prepare.py').read_bytes()),
        'run.py': sha256((adapter_root / 'run.py').read_bytes()),
        'source_smoke.py': EXPECTED_SOURCE_SMOKE_SHA256,
        'overlay_smoke.py': sha256(overlay_smoke.read_bytes()),
    }
    if manifest.get('adapter_components') != expected_components:
        raise ValueError('adapter component hashes do not match preparation manifest')
    bundle = hashlib.sha256()
    for name, digest in sorted(expected_components.items()):
        bundle.update(name.encode() + b'\0' + digest.encode() + b'\n')
    if manifest.get('adapter_bundle_sha256') != bundle.hexdigest():
        raise ValueError('adapter bundle hash mismatch')

    result = {
        'success': False,
        'source_commit': commit,
        'source_smoke_sha256': EXPECTED_SOURCE_SMOKE_SHA256,
        'overlay_smoke_sha256': manifest['overlay_smoke_sha256'],
        'adapter_bundle_sha256': manifest['adapter_bundle_sha256'],
        'platform': 'linux/arm64',
        'runner_architecture': platform.machine(),
        'preparation_sha256': preparation.get('preparation_sha256'),
        'assembly_target': assembly.get('target'),
    }
    sys.path.insert(0, str(overlay))
    sys.path.insert(1, str(source_root / 'pgrx'))
    os.chdir(source_root)
    sys.argv = [str(source_root / 'pgrx/downstream.py'), args.stage,
                '--preparation', str(args.preparation),
                '--assembly', str(args.assembly),
                '--output', str(output)]
    if args.cnpg_version:
        sys.argv += ['--cnpg-version', args.cnpg_version]
    try:
        import downstream
        downstream.main()
        result['success'] = True
        downstream_result = json.loads((output / 'result.json').read_text())
        result['signature_verified'] = True
        result['image'] = downstream_result['image']
        result['run_id'] = downstream_result['run_id']
        result['target'] = downstream_result['target']
        result['cnpg_version'] = args.cnpg_version
    except BaseException as error:
        result['error'] = f'{type(error).__name__}: {error}'
        result['traceback'] = traceback.format_exc()
        raise
    finally:
        output.mkdir(parents=True, exist_ok=True)
        result_path = output / 'result.json'
        if result_path.exists():
            result['downstream_result_sha256'] = sha256(result_path.read_bytes())
        (output / 'adapter.json').write_text(json.dumps(result, indent=2) + '\n')


if __name__ == '__main__':
    main()
