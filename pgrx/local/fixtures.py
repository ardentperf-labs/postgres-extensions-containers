"""Native generator compatibility and generic signed-consumer integration fixtures."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import uuid

from verify import verify
from workflow import ROOT


def run_fixtures(output, pins, private, public):
    output.mkdir(parents=True)
    text = (ROOT / '.github/workflows/pgrx_targets.yml').read_text()
    generator = re.search(r'SBOM_GENERATOR: (\S+@sha256:[a-f0-9]{64})', text).group(1)
    builder = 'pgrx-fixture-' + uuid.uuid4().hex[:16]
    config = output / 'buildkit.toml'
    config.write_text('[registry."registry.pg-extensions:5000"]\n  http = true\n[registry."registry-copy.pg-extensions:5000"]\n  http = true\n')
    subprocess.run(['docker', 'buildx', 'create', '--name', builder, '--driver', 'docker-container',
        '--driver-opt', 'network=pg-extensions-e2e', '--driver-opt', 'image=' + pins['images']['buildkit'], '--buildkitd-config', str(config)], check=True)
    old_builder = os.environ.get('BUILDX_BUILDER')
    os.environ['BUILDX_BUILDER'] = builder
    environment = {**os.environ, 'COSIGN_PASSWORD': ''}
    try:
        for variant in ['debian', 'hook']:
            directory = output / variant
            shutil.copytree(ROOT / 'pgrx/tests/fixtures/generator', directory)
            if variant == 'debian':
                dockerfile = directory / 'Dockerfile'
                dockerfile.write_text(dockerfile.read_text().replace('COPY augment_spdx.py /usr/local/share/cnpg-sbom/augment_spdx.py\n', ''))
            repository = 'registry.pg-extensions:5000/pgrx-fixtures'
            tag = repository + ':' + variant + '-' + uuid.uuid4().hex[:16]
            metadata = directory / 'metadata.json'
            subprocess.run(['docker', 'buildx', 'build', '--builder', builder, '--platform', 'linux/amd64',
                '--tag', tag, '--attest', 'type=sbom,generator=' + generator, '--attest', 'type=provenance,mode=max',
                '--output', 'type=image,oci-mediatypes=true,oci-artifact=true,push=true', '--metadata-file', str(metadata), str(directory)], check=True)
            digest = json.loads(metadata.read_text())['containerimage.digest']
            image = repository + '@' + digest
            def sign(reference):
                subprocess.run(['cosign', 'sign', '--yes', '--key', str(private), '--new-bundle-format=false',
                    '--use-signing-config=false', '--tlog-upload=false', '--allow-http-registry', reference], env=environment, check=True)
            try:
                verify(image, 'linux/amd64', directory / 'unsigned', key=public, insecure=True)
            except (ValueError, subprocess.CalledProcessError):
                pass
            else:
                raise ValueError('consumer accepted an unsigned index')
            if (directory / 'unsigned').exists():
                raise ValueError('unsigned verification published output')
            sign(image)
            graph = verify(image, 'linux/amd64', directory / 'source', key=public, insecure=True)
            document = graph['platforms']['linux/amd64']['spdx']
            if (document.get('comment') == 'cnpg-pgrx-hook-api-v1-native-compatibility-passed') != (variant == 'hook'):
                raise ValueError('generator hook compatibility result mismatch')
            # Repeated output, wrong requested platform and unsigned index fail closed.
            for platform, path in [('linux/amd64', directory / 'source'), ('linux/arm64', directory / 'wrong-platform')]:
                try:
                    verify(image, platform, path, key=public, insecure=True)
                except (ValueError, subprocess.CalledProcessError):
                    pass
                else:
                    raise ValueError('consumer accepted a negative fixture')
            if (directory / 'wrong-platform').exists():
                raise ValueError('failed verification published output')
            dry = json.loads(subprocess.check_output(['docker', 'buildx', 'imagetools', 'create', '--dry-run', image]))
            if dry['manifests'] != graph['index']['manifests']:
                raise ValueError('single-platform merge changed fixture descriptors')
            destination = 'registry-copy.pg-extensions:5000/pgrx-fixtures:' + variant + '-' + uuid.uuid4().hex[:16]
            subprocess.run(['skopeo', 'copy', '--all', '--preserve-digests', '--src-tls-verify=false', '--dest-tls-verify=false',
                'docker://' + image, 'docker://' + destination], check=True)
            raw = subprocess.check_output(['docker', 'buildx', 'imagetools', 'inspect', destination, '--raw'])
            if 'sha256:' + hashlib.sha256(raw).hexdigest() != digest:
                raise ValueError('copy altered fixture index')
            copied = destination.rsplit(':', 1)[0] + '@' + digest
            sign(copied)
            verify(copied, 'linux/amd64', directory / 'destination', key=public, insecure=True)
            for where in ['source', 'destination']:
                subprocess.run(['trivy', 'sbom', '--scanners', 'vuln,license', '--format', 'json', '--output',
                    str(directory / where / 'trivy.json'), str(directory / where / 'sbom.spdx.json')], check=True)
        (output / 'result.json').write_text(json.dumps({'success': True, 'platform': 'linux/amd64', 'generator': generator}) + '\n')
    finally:
        if old_builder is None:
            os.environ.pop('BUILDX_BUILDER', None)
        else:
            os.environ['BUILDX_BUILDER'] = old_builder
        subprocess.run(['docker', 'buildx', 'rm', builder], check=True)
