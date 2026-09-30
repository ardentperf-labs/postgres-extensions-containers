"""Local registry/runner/signing adapters. Never publishes outside local registries."""
import base64
import json
import os
from pathlib import Path
import platform
import subprocess

ROOT=Path(__file__).resolve().parents[2]


def run(*args,**kwargs):return subprocess.run(args,check=True,**kwargs)


def setup(directory):
    if platform.machine()!='x86_64':raise ValueError('native validation requires x86_64')
    if subprocess.check_output(['docker','info','--format','{{.Architecture}}'],text=True).strip() not in ('x86_64','amd64'):raise ValueError('Docker worker must be native amd64')
    pins=json.loads((ROOT/'pgrx/dependencies/workflow-tools.json').read_text())
    if subprocess.run(['docker','network','inspect','pg-extensions-e2e'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode:
        run('docker','network','create','pg-extensions-e2e')
    for name,port in [('registry.pg-extensions',5000),('registry-copy.pg-extensions',5001)]:
        inspect=subprocess.run(['docker','inspect',name],capture_output=True,text=True)
        if inspect.returncode:
            run('docker','run','-d','--platform','linux/amd64','--name',name,'--label','cnpg.pgrx.local=true','--network','pg-extensions-e2e','-p',f'{port}:5000',pins['images']['registry'])
        else:
            info=json.loads(inspect.stdout)[0]
            if info['Config']['Image']!=pins['images']['registry'] or not info['State']['Running'] or 'pg-extensions-e2e' not in info['NetworkSettings']['Networks']:raise ValueError('incompatible existing registry: '+name)
    run('docker','pull','--platform','linux/amd64',pins['images']['runner'])
    arch=subprocess.check_output(['docker','image','inspect',pins['images']['runner'],'--format','{{.Architecture}}'],text=True).strip()
    if arch!='amd64':raise ValueError('act runner must be native amd64')
    # Host clients need the same repository names as the Docker-network callers.
    # Use registry container IPs on the host; never inject loopback into act jobs.
    hosts=Path('/etc/hosts');content=hosts.read_text()
    for name in ['registry.pg-extensions','registry-copy.pg-extensions']:
        ip=json.loads(subprocess.check_output(['docker','inspect',name]))[0]['NetworkSettings']['Networks']['pg-extensions-e2e']['IPAddress']
        if not any(name in line.split()[1:] for line in content.splitlines() if line and not line.startswith('#')):
            line='\n'+ip+' '+name+' # pgrx local validation\n'
            subprocess.run(['sudo','-n','tee','-a','/etc/hosts'],input=line,text=True,check=True,stdout=subprocess.DEVNULL)
    private=directory/'cosign.key';public=directory/'cosign.pub'
    if not private.exists():
        run('cosign','generate-key-pair','--output-key-prefix',str(directory/'cosign'),env={**os.environ,'COSIGN_PASSWORD':''})
        private.chmod(0o600)
    secrets=directory/'act.secrets'
    secrets.write_text('PGRX_COSIGN_PRIVATE_KEY_B64='+base64.b64encode(private.read_bytes()).decode()+'\nPGRX_COSIGN_PUBLIC_KEY_B64='+base64.b64encode(public.read_bytes()).decode()+'\n')
    secrets.chmod(0o600)
    return pins,secrets
