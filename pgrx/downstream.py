#!/usr/bin/env python3
"""Shared signing, scanning and promotion steps for each assembled target."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from prepare import save
from record import load_preparation
from verify import verify_signature as check_signature,validate_layout,verify
from workflow import boolean

ISSUER='https://token.actions.githubusercontent.com'


def main():
    parser=argparse.ArgumentParser();parser.add_argument('stage',choices=['sign','security','smoke','promote']);parser.add_argument('--preparation',required=True,type=Path);parser.add_argument('--assembly',required=True,type=Path);parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--cnpg-version')
    args=parser.parse_args();preparation=load_preparation(args.preparation);assembly=json.loads((args.assembly/'assembly.json').read_text())
    if assembly['preparation_sha256']!=preparation['preparation_sha256'] or assembly['target'] not in preparation['targets'] or assembly['run_id']!=preparation['run_id']:raise ValueError('wrong assembly artifact')
    local=boolean(preparation['inputs'].get('local',False));image=assembly['image']
    if args.output.exists():raise ValueError('fresh downstream output required')
    args.output.mkdir(parents=True)
    with tempfile.TemporaryDirectory(prefix='pgrx-trust-') as temporary:
        key=Path(temporary)/'cosign.key';public=Path(temporary)/'cosign.pub'
        if local:
            public.write_bytes(base64.b64decode(os.environ['PGRX_COSIGN_PUBLIC_KEY_B64'],validate=True))
            if args.stage in ('sign','promote'):
                key.write_bytes(base64.b64decode(os.environ['PGRX_COSIGN_PRIVATE_KEY_B64'],validate=True));key.chmod(0o600)
        import re
        policy='^https://github\\.com/'+re.escape(os.environ.get('GITHUB_REPOSITORY','ardentperf/postgres-extensions-containers'))+'/\\.github/workflows/(bake_targets|pgrx_targets)\\.yml@'+re.escape(os.environ.get('GITHUB_REF','refs/heads/main'))+'$'
        def sign(reference):
            command=['cosign','sign','--yes','--new-bundle-format=false','--use-signing-config=false']
            if local:command+=['--key',str(key),'--tlog-upload=false','--allow-http-registry']
            subprocess.run([*command,reference],check=True)
        def verify_signature(reference):
            return check_signature(reference,public if local else None,None if local else policy,None if local else ISSUER,local)
        if args.stage=='sign':
            sign(image);save(args.output/'signature.json',verify_signature(image))
        elif args.stage=='security':
            for platform in assembly['platforms']:
                output=args.output/platform.split('/')[1]
                verify(image,platform,output,public if local else None,None if local else policy,None if local else ISSUER,local)
                subprocess.run(['trivy','sbom','--scanners','vuln,license','--format','json','--output',str(output/'trivy.json'),str(output/'sbom.spdx.json')],check=True)
        elif args.stage=='smoke':
            from smoke import smoke
            verify_signature(image)
            assembly['_directory']=str(args.assembly)
            smoke(preparation,assembly,args.output,args.cnpg_version)
        elif args.stage=='promote':
            if not local and (os.environ.get('GITHUB_REF')!='refs/heads/main' or os.environ.get('GITHUB_EVENT_NAME') not in ('push','workflow_dispatch')):raise ValueError('production promotion requires a trusted main event')
            verify_signature(image)
            tags=[]
            for tag in assembly['tags']:
                repo,version=tag.rsplit(':',1)
                if local:destination='registry-copy.pg-extensions:5000/'+repo.split('/',1)[1]+':'+version
                else:destination=repo.removesuffix('-testing')+':'+version
                subprocess.run(['skopeo','copy','--all','--preserve-digests',*(['--src-tls-verify=false','--dest-tls-verify=false'] if local else []),'docker://'+image,'docker://'+destination],check=True)
                raw=subprocess.check_output(['docker','buildx','imagetools','inspect',destination,'--raw'])
                if 'sha256:'+hashlib.sha256(raw).hexdigest()!=assembly['index_digest']:raise ValueError('copy changed index digest')
                copied=destination.rsplit(':',1)[0]+'@'+assembly['index_digest'];sign(copied)
                for platform in assembly['platforms']:
                    verify(copied,platform,args.output/('copy-'+str(len(tags))+'-'+platform.split('/')[1]),public if local else None,None if local else policy,None if local else ISSUER,local)
                tags.append(destination)
            save(args.output/'destination.json',{'tags':tags,'index_digest':assembly['index_digest']})
    save(args.output/'result.json',{'stage':args.stage,'success':True,'target':assembly['target'],'image':image,'run_id':assembly['run_id'],'preparation_sha256':preparation['preparation_sha256']})

if __name__=='__main__':main()
