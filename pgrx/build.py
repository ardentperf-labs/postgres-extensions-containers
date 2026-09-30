#!/usr/bin/env python3
"""One native platform job; BuildKit alone produces the image and attestations."""
import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile

from record import capture,expected_row,load_preparation
from prepare import digest
from workflow import ROOT,boolean


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--preparation',required=True,type=Path);parser.add_argument('--row',required=True);parser.add_argument('--output',required=True,type=Path)
    args=parser.parse_args();preparation=load_preparation(args.preparation);row=expected_row(preparation,args.row)
    local=boolean(preparation['inputs'].get('local',False));multi=boolean(preparation['inputs'].get('local_multiplatform',False))
    native={'x86_64':'amd64','aarch64':'arm64'}[platform.machine()]
    daemon=subprocess.check_output(['docker','info','--format','{{.Architecture}}'],text=True).strip()
    if daemon not in ({'amd64','x86_64'} if native=='amd64' else {'arm64','aarch64'}):raise ValueError('daemon/job architecture mismatch')
    if local and native!='amd64':raise ValueError('local job must be native amd64')
    if row['architecture']!=native and not(local and multi and row['architecture']=='arm64'):raise ValueError('foreign build before native gate')
    if multi:
        # The local harness passes the same receipt outside the build context.
        from local.validate import verify_receipt
        verify_receipt(Path(os.environ['PGRX_NATIVE_REPORT']),preparation['inputs']['native_gate_sha256'])
    definition=json.loads((args.preparation/(row['id']+'.json')).read_text())
    if digest(definition)!=row['definition_sha256']:raise ValueError('altered build definition')
    pins=json.loads((ROOT/'pgrx/dependencies/workflow-tools.json').read_text())
    name='pgrx-'+row['id']
    with tempfile.TemporaryDirectory(prefix='pgrx-builder-') as temp:
        config=Path(temp)/'buildkit.toml'
        config.write_text('[worker.oci]\n  max-parallelism = 1\n'+('''[registry."registry.pg-extensions:5000"]
  http = true
[registry."registry-copy.pg-extensions:5000"]
  http = true
''' if local else ''))
        command=['docker','buildx','create','--name',name,'--driver','docker-container','--driver-opt','image='+pins['images']['buildkit'],'--buildkitd-config',str(config)]
        if local:command+=['--driver-opt','network=pg-extensions-e2e']
        subprocess.run(command,check=True)
        subprocess.run(['docker','buildx','inspect',name,'--bootstrap'],check=True)
        worker=subprocess.check_output(['docker','exec','buildx_buildkit_'+name+'0','uname','-m'],text=True).strip()
        if worker!=platform.machine():raise ValueError('selected BuildKit worker is not native')
        metadata=Path(temp)/'metadata.json'
        subprocess.run(['docker','buildx','bake','--builder',name,'-f',str(args.preparation/(row['id']+'.json')),row['target'],'--metadata-file',str(metadata),'--progress','plain'],cwd=ROOT,check=True)
        image_digest=json.loads(metadata.read_text())[row['target']]['containerimage.digest']
        capture(args.preparation,row['id'],image_digest,args.output)
        # Failure retains its uniquely named builder for diagnostics.
        subprocess.run(['docker','buildx','rm',name],check=True)

if __name__=='__main__':main()
