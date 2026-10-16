#!/usr/bin/env python3
"""Resolve both architectures using native amd64 apt, never ARM execution.

The ARM installed set comes from the locked base index's published SPDX.
APT's signed indexes supply full control records and SHA256 download hashes.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.parse

from workflow import ROOT

PACKAGES = ['build-essential','ca-certificates','clang','cmake','curl','git','jq','libclang-dev',
            'libssl-dev','pkg-config','python3','postgresql-server-dev-18','xz-utils','patch','libopenblas-dev']


def refresh_apt():
    root = ROOT / 'pgrx/dependencies'
    bases = json.loads((root / 'bases.json').read_text())
    with tempfile.TemporaryDirectory(prefix='pgrx-apt-refresh-') as temporary:
        temp = Path(temporary)
        for suite in ['bookworm', 'trixie']:
            reference = 'ghcr.io/cloudnative-pg/postgresql:18-minimal-' + suite
            base = bases[reference]
            for architecture in ['amd64', 'arm64']:
                image = reference + '@' + base['platforms']['linux/amd64']
                container = subprocess.check_output(['docker','run','-d','--platform','linux/amd64','--user','0',image,'sleep','900'],text=True).strip()
                try:
                    prefix = ''
                    status = ''
                    if architecture == 'arm64':
                        document = json.loads(subprocess.check_output(['docker','buildx','imagetools','inspect',reference+'@'+base['index_digest'],'--format','{{json .SBOM}}']))['linux/arm64']['SPDX']
                        packages = []
                        for package in document['packages']:
                            refs = [r['referenceLocator'] for r in package.get('externalRefs',[]) if r.get('referenceType')=='purl' and r['referenceLocator'].startswith('pkg:deb/')]
                            if not refs:continue
                            arch = urllib.parse.parse_qs(urllib.parse.urlparse(refs[0]).query)['arch'][0]
                            packages.append(package['name']+':'+arch+'='+package['versionInfo'])
                        if not packages:raise ValueError('locked base has no ARM package evidence')
                        selection = temp/'base-packages';selection.write_text('\n'.join(packages)+'\n')
                        subprocess.run(['docker','cp',str(selection),container+':/tmp/base-packages'],check=True)
                        prefix = "sed -i 's/amd64/arm64/g' /etc/apt/sources.list.d/*\n"
                        status = '''
: > /tmp/arm-status
while read -r package; do
  info=$(apt-cache -o APT::Architecture=arm64 -o APT::Architectures=arm64 show "$package")
  test -n "$info"
  printf '%s\\nStatus: install ok installed\\n\\n' "$info" >> /tmp/arm-status
done < /tmp/base-packages
'''
                    options = '-o APT::Architecture='+architecture+' -o APT::Architectures='+architecture
                    script = 'set -Eeuo pipefail\n'+prefix+'apt-get '+options+' update >&2\n'+status
                    if architecture=='arm64':options+=' -o Dir::State::status=/tmp/arm-status'
                    script += 'apt-get '+options+' -o Acquire::ForceHash=sha256 --print-uris --yes --download-only install '+' '.join(PACKAGES)+'\n'
                    raw = subprocess.check_output(['docker','exec',container,'bash','-c',script],text=True)
                    rows=[]
                    for line in raw.splitlines():
                        match=re.fullmatch(r"'([^']+)' (\S+) \d+ SHA256:([a-f0-9]{64})",line)
                        if match:rows.append((match[3],match[2],match[1]))
                    if not rows:raise ValueError('apt returned no locked package artifacts')
                    (root/'apt'/f'{suite}-{architecture}.tsv').write_text(''.join('\t'.join(row)+'\n' for row in sorted(rows,key=lambda r:r[1])))
                finally:subprocess.run(['docker','rm','-f',container],check=True,stdout=subprocess.DEVNULL)
    write_ownership()


def write_ownership():
    root=ROOT/'pgrx/dependencies'
    lock={'schema_version':1,'base_lock_sha256':hashlib.sha256((root/'bases.json').read_bytes()).hexdigest(),
          'packages':PACKAGES,'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((root/'apt').glob('*.tsv'))}}
    (root/'apt/lock.json').write_text(json.dumps(lock,indent=2)+'\n')

if __name__=='__main__':refresh_apt()
