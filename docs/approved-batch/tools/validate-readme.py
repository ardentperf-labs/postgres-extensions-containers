#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
"""Apply a README's declarative examples to an existing isolated Kind environment.

Requires kubectl and PyYAML. Supply the local registry used by the target's
successful full test; that workflow also builds its local image dependencies.
Only extension image references/pull policy and resource namespaces are changed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time
import uuid
import urllib.request

import yaml

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('target')
parser.add_argument('--registry', required=True)
parser.add_argument('--kubeconfig', required=True)
parser.add_argument('--registry-http', required=True, help='Host-accessible registry URL')
parser.add_argument('--output', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
readme = root / args.target / 'README.md'
namespace = 'readme-' + uuid.uuid4().hex[:12]
result = {'target': args.target, 'readme_sha256': hashlib.sha256(readme.read_bytes()).hexdigest(),
          'runtime_architecture': 'amd64', 'distribution': 'trixie',
          'registry': args.registry, 'resources': [], 'images': {}, 'result': 'FAIL',
          'started_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}
base = ['kubectl', '--kubeconfig', args.kubeconfig, '-n', namespace]


def kubectl(*words, data=None):
    proc = subprocess.run([*base, *words], input=data, capture_output=True, text=True, timeout=360)
    if proc.returncode:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip())
    return proc.stdout


def local_images(value):
    if isinstance(value, dict):
        for key, child in list(value.items()):
            if key == 'reference' and isinstance(child, str):
                match = re.fullmatch(r'ghcr.io/cnpg-extensions/([^:]+):(.+)', child)
                if match and (root / match[1] / 'metadata.hcl').exists():
                    tag = f'{match[1]}-testing:{match[2]}'
                    request = urllib.request.Request(f'{args.registry_http}/v2/{match[1]}-testing/manifests/{match[2]}', headers={'Accept': 'application/vnd.oci.image.index.v1+json'})
                    with urllib.request.urlopen(request, timeout=30) as response:
                        digest = response.headers.get('Docker-Content-Digest', 'sha256:' + hashlib.sha256(response.read()).hexdigest())
                    value[key] = f'{args.registry}/{tag}@{digest}'
                    result['images'][tag] = digest
                    value['pullPolicy'] = 'Always'
            else:
                local_images(child)
    elif isinstance(value, list):
        for child in value:
            local_images(child)


try:
    documents = []
    for block in re.findall(r'(?:```|~~~)ya?ml\n(.*?)(?:```|~~~)', readme.read_text(), re.S):
        for document in yaml.safe_load_all(block):
            if isinstance(document, dict) and document.get('apiVersion') and document.get('kind'):
                documents.append(document)
    assert sum(d['kind'] == 'Cluster' for d in documents) == 1, 'Expected exactly one Cluster example'
    kubectl('create', 'namespace', namespace)
    for document in documents:
        local_images(document)
        document.setdefault('metadata', {})['namespace'] = namespace
        kind = document['kind']
        name = document['metadata']['name']
        kubectl('apply', '--validate=strict', '-f', '-', data=yaml.safe_dump(document))
        result['resources'].append({'kind': kind, 'name': name})
        if kind == 'Cluster':
            kubectl('wait', '--for=condition=Ready', f'cluster/{name}', '--timeout=300s')
        elif kind == 'Database':
            kubectl('wait', '--for=jsonpath={.status.applied}=true', f'database/{name}', '--timeout=180s')
            status = json.loads(kubectl('get', f'database/{name}', '-o', 'json'))['status']
            applied = {entry['name']: entry.get('applied') for entry in status.get('extensions', [])}
            for extension in document['spec'].get('extensions', []):
                assert applied.get(extension['name']) is True, f"Unapplied extension: {extension['name']}"
        elif kind == 'Job':
            kubectl('wait', '--for=condition=Complete', f'job/{name}', '--timeout=180s')
    result['result'] = 'PASS'
except Exception as error:
    result['error'] = str(error)
    # Diagnostic statuses remain in the caller's private log, not the evidence.
    try:
        print(kubectl('get', 'clusters,databases,pods,jobs', '-o', 'wide'), flush=True)
    except Exception:
        pass
finally:
    try:
        kubectl('delete', 'namespace', namespace, '--ignore-not-found', '--wait=true', '--timeout=120s')
    except Exception as error:
        result['cleanup_error'] = str(error)
        result['result'] = 'FAIL'
    Path(args.output).write_text(json.dumps(result, indent=2) + '\n')
print(f"{args.target}: {result['result']}", flush=True)
raise SystemExit(0 if result['result'] == 'PASS' else 1)
