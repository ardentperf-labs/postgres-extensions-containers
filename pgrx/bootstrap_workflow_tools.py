#!/usr/bin/env python3
"""Install checksum-pinned executables into a private workflow directory."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import uuid
import tarfile
import urllib.request

ROOT=Path(__file__).resolve().parent

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True,type=Path);args=parser.parse_args()
    architecture={'x86_64':'amd64','aarch64':'arm64'}[platform.machine()]
    pins=json.loads((ROOT/'dependencies/workflow-tools.json').read_text())
    args.output.mkdir(parents=True,exist_ok=True)
    for name,tool in pins['tools'].items():
        entry=tool['platforms'][architecture];data=urllib.request.urlopen(entry['url']).read()
        if hashlib.sha256(data).hexdigest()!=entry['sha256']:raise ValueError('tool checksum mismatch: '+name)
        archive=args.output/(name+'.download');archive.write_bytes(data)
        if entry['url'].endswith('.tar.gz'):
            with tarfile.open(archive) as tar:
                members=[m for m in tar if m.isfile() and Path(m.name).name==name]
                if len(members)!=1:raise ValueError('ambiguous tool archive')
                data=tar.extractfile(members[0]).read()
        binary=args.output/name;binary.write_bytes(data);binary.chmod(0o755);archive.unlink()
    (args.output/'skopeo').write_text('#!/bin/sh\nexec python3 '+str(ROOT/'skopeo.py')+' "$@"\n')
    (args.output/'skopeo').chmod(0o755)
    if os.getenv('PGRX_LOCAL')=='true':
        config=args.output/'buildkit-registry.toml'
        config.write_text('[registry."registry.pg-extensions:5000"]\n  http = true\n[registry."registry-copy.pg-extensions:5000"]\n  http = true\n')
        builder='pgrx-tools-'+uuid.uuid4().hex[:16]
        subprocess.run(['docker','buildx','create','--name',builder,'--driver','docker-container','--driver-opt','image='+pins['images']['buildkit'],'--buildkitd-config',str(config)],check=True)
        if os.getenv('GITHUB_ENV'):
            with open(os.environ['GITHUB_ENV'],'a') as stream:stream.write('BUILDX_BUILDER='+builder+'\n')
    if os.getenv('GITHUB_PATH'):

        with open(os.environ['GITHUB_PATH'],'a') as stream:stream.write(str(args.output.resolve())+'\n')

if __name__=='__main__':main()
