#!/usr/bin/env python3
"""Typed workflow selection and source identity shared by hosted and act jobs."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def execute(command, *, root=ROOT, env=None):
    return subprocess.run(command,cwd=root,env=env,check=True,capture_output=True,text=True).stdout


def boolean(value):
    if isinstance(value,bool): return value
    if value not in ('true','false'): raise ValueError('boolean must be true or false')
    return value == 'true'


def metadata(path):
    definition=json.loads(execute(['docker','buildx','bake','-f',str(path),'-f',str(ROOT/'pgrx/inventory.hcl'),'--print','inventory']))
    value=json.loads(definition['target']['inventory']['args']['METADATA'])
    system=value.get('build_system','debian')
    if system not in ('debian','pgrx'):raise ValueError(f'unsupported build_system: {system!r}')
    return value


def discover():
    return {p.parent.name: value for p in sorted(ROOT.glob('*/metadata.hcl')) if (value:=metadata(p)).get('build_system','debian') == 'pgrx'}


def source_digest(root=ROOT):
    paths=json.loads(base64.b64decode(os.environ['PGRX_SOURCE_FILES'])) if os.getenv('PGRX_SOURCE_FILES') else execute(['git','ls-files','-z','--cached','--others','--exclude-standard'],root=root).split('\0')
    digest=hashlib.sha256()
    for name in sorted(set(paths)-{''}):
        if Path(name).name == 'AGENTS.md':continue
        path=root/name
        if not path.exists() and not path.is_symlink():continue
        data=os.readlink(path).encode() if path.is_symlink() else path.read_bytes()
        digest.update(name.encode()+b'\0'+str(path.lstat().st_mode & 0o777).encode()+b'\0'+hashlib.sha256(data).digest())
    return digest.hexdigest()


def select(inputs, inventory):
    local=boolean(inputs.get('local',False)); multi=boolean(inputs.get('local_multiplatform',False))
    extension=inputs['extension_name']
    if extension not in inventory:raise ValueError(f'not a PGRX extension: {extension}')
    distro=inputs.get('distro','');platform=inputs.get('platform','');target=inputs.get('pg_target','')
    if not local:
        if any((distro,platform,target,multi,inputs.get('local_run_id'),inputs.get('native_gate_sha256'))):
            raise ValueError('local selectors require local=true')
    else:
        if not re.fullmatch('[A-Za-z0-9][A-Za-z0-9_.-]{7,100}',inputs.get('local_run_id','')):raise ValueError('unique local_run_id required')
        if distro not in inventory[extension]['versions']:raise ValueError('local distro must be metadata-declared')
        if multi:
            if extension!='pg-session-jwt' or distro!='trixie' or platform:raise ValueError('final pass restricted to session-jwt/Trixie with empty platform')
            if not re.fullmatch('[a-f0-9]{64}',inputs.get('native_gate_sha256','')):raise ValueError('native gate receipt required')
        elif platform!='linux/amd64':raise ValueError('ordinary local mode requires linux/amd64')
    return ['linux/amd64','linux/arm64'] if not local or multi else ['linux/amd64']


def changed_extensions(paths, inventory):
    shared=('pgrx/','docker-bake-pgrx.hcl','.github/workflows/pgrx.yml','.github/workflows/pgrx_targets.yml','dagger/maintenance/','Taskfile.yml','renovate.json')
    if any(any(p.startswith(prefix) for prefix in shared) for p in paths):return sorted(inventory)
    return sorted({p.split('/')[0] for p in paths}&set(inventory))


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--inputs',type=Path);parser.add_argument('--changed-paths',type=Path)
    args=parser.parse_args();inventory=discover()
    if args.inputs:
        inputs=json.loads(args.inputs.read_text());select(inputs,inventory);result=[inputs['extension_name']]
    elif args.changed_paths:result=changed_extensions(args.changed_paths.read_text().splitlines(),inventory)
    else:result=sorted(inventory)
    print(json.dumps(result))

if __name__=='__main__':main()
