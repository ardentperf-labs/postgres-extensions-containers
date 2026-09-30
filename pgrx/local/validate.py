#!/usr/bin/env python3
"""Run real act workflows and enforce native-before-emulation acceptance."""
import argparse
import base64
import hashlib
import json
import os
import platform
import shutil
from pathlib import Path
import subprocess
import sys
import uuid

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'pgrx'))
from workflow import discover,source_digest
from local.services import setup
from local.receipts import verify_receipt, extract_artifacts, reconcile, write_receipt
from local.fixtures import run_fixtures
from local.renovate import check_renovate


def invoke_case(extension,distro,directory,pins,secrets,multi=False,receipt=None,target=None,cnpg_version=None):
    if cnpg_version is None:
        cnpg_version=json.loads((ROOT/'pgrx/dependencies/fixtures/lock.json').read_text())['selector']
    identity='pgrx-'+uuid.uuid4().hex
    case=directory/identity;case.mkdir()
    paths=subprocess.check_output(['git','ls-files','-z','--cached','--others','--exclude-standard'],cwd=ROOT).decode().split('\0')
    paths=[p for p in paths if p and Path(p).name!='AGENTS.md' and (ROOT/p).exists()]
    envfile=case/'act.env'
    envfile.write_text('PGRX_SOURCE_FILES='+base64.b64encode(json.dumps(paths).encode()).decode()+'\nPGRX_SOURCE_GIT_SHA='+subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()+'\n')
    command=['act','workflow_dispatch','-W','.github/workflows/pgrx.yml','--input','extension_name='+extension,'--input','local=true','--input','local_multiplatform='+str(multi).lower(),
             '--input','platform='+('' if multi else 'linux/amd64'),'--input','distro='+distro,'--input','cnpg_version='+cnpg_version,'--input','local_run_id='+identity,
             '-P','ubuntu-24.04='+pins['images']['runner'],'-P','ubuntu-24.04-arm='+pins['images']['runner'],'--container-architecture','linux/amd64','--concurrent-jobs','1',
             '--network','pg-extensions-e2e','--artifact-server-path',str(case/'artifacts'),'--env-file',str(envfile),'--secret-file',str(secrets)]
    if target:command+=['--input','pg_target='+target]
    if receipt:
        checksum=hashlib.sha256(receipt.read_bytes()).hexdigest();verify_receipt(receipt,checksum)
        command+=['--input','native_gate_sha256='+checksum]
        # Mount only the receipt, outside the source context; never a private key.
        command+=['--container-options','--mount type=bind,src='+str(receipt.parent)+',dst=/pgrx-native,readonly','--env','PGRX_NATIVE_REPORT=/pgrx-native/'+receipt.name]
    (case/'command.json').write_text(json.dumps(command,indent=2)+'\n')
    with (case/'act.log').open('w') as log:
        process=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
    if process.returncode:raise RuntimeError('workflow failed; see '+str(case/'act.log'))
    return case


def main():
    parser=argparse.ArgumentParser();parser.add_argument('phase',choices=['native','multiplatform','case'])
    parser.add_argument('--output',type=Path,default=Path('/tmp')/('pgrx-validation-'+uuid.uuid4().hex))
    parser.add_argument('--extension');parser.add_argument('--distro');parser.add_argument('--cnpg-version');parser.add_argument('--native-report',type=Path)
    args=parser.parse_args()
    os.environ['PGRX_LOCAL']='true'
    initial_source=source_digest()
    fixtures=json.loads((ROOT/'pgrx/dependencies/fixtures/lock.json').read_text())
    cnpg_version=args.cnpg_version or fixtures['selector']
    if cnpg_version not in fixtures['operators']:raise ValueError('fixture lock must be resolved for the selected CNPG version')
    args.output.mkdir(parents=True,exist_ok=False)
    subprocess.run([sys.executable,str(ROOT/'pgrx/bootstrap_workflow_tools.py'),'--output',str(args.output/'bin')],check=True)
    os.environ['PATH']=str(args.output/'bin')+':'+os.environ['PATH']
    pins,secrets=setup(args.output)
    (args.output/'preflight.json').write_text(json.dumps({'host':platform.machine(),
        'daemon':subprocess.check_output(['docker','info','--format','{{.Architecture}}'],text=True).strip(),
        'disk_free_bytes':shutil.disk_usage(ROOT).free,'workspace_sha256':source_digest(),
        'cpu_count':os.cpu_count(),'tool_pins':pins},indent=2)+'\n')
    if args.phase=='case':
        if not args.extension or not args.distro:parser.error('case requires extension and distro')
        print(invoke_case(args.extension,args.distro,args.output,pins,secrets,cnpg_version=cnpg_version));return
    if args.phase=='multiplatform':
        if args.extension!='pg-session-jwt' or args.distro!='trixie' or not args.native_report:raise ValueError('bounded final case and native report required')
        verify_receipt(args.native_report,hashlib.sha256(args.native_report.read_bytes()).hexdigest())
        # Enabling ARM execution is deliberately after full receipt reconciliation.
        subprocess.run(['docker','run','--rm','--privileged','--platform','linux/amd64',pins['images']['binfmt'],'--install','arm64'],check=True)
        case=invoke_case('pg-session-jwt','trixie',args.output,pins,secrets,multi=True,receipt=args.native_report.resolve(),cnpg_version=cnpg_version)
        destination=args.output/'final-artifacts';extract_artifacts(case,destination)
        result=reconcile(destination,'pg-session-jwt','trixie','18',['linux/amd64','linux/arm64'])
        (args.output/'multiplatform-report.json').write_text(json.dumps(result,indent=2)+'\n')
        print(args.output/'multiplatform-report.json');return
    # Never manufacture a native gate receipt from a partial run or exit code.
    subprocess.run([sys.executable,'-m','unittest','discover','-s','sbom-generator/tests','-p','test_*.py'],cwd=ROOT,check=True)
    subprocess.run([sys.executable,'-m','unittest','discover','-s','pgrx/tests','-p','test_*.py'],cwd=ROOT,check=True)
    module_file=ROOT/'dagger/maintenance/dagger.json'
    module_bytes=module_file.read_bytes()
    try:
        subprocess.run(['dagger','develop','-m','./dagger/maintenance'],cwd=ROOT,check=True)
    finally:
        # Generate the ignored client without upgrading the shared module's
        # declared minimum engine version as a side effect of local validation.
        module_file.write_bytes(module_bytes)
    subprocess.run(['go','test','./...'],cwd=ROOT/'dagger/maintenance',env={**os.environ,'DAGGER_SESSION_PORT':'1','DAGGER_SESSION_TOKEN':'test'},check=True)
    subprocess.run(['actionlint','.github/workflows/pgrx.yml','.github/workflows/pgrx_targets.yml'],cwd=ROOT,check=True)
    acceptance=args.output/'acceptance';acceptance.mkdir()
    # Run the actual repository unit-test workflow in the same native runner.
    with (acceptance/'act-unit.log').open('w') as log:
        subprocess.run(['act','workflow_dispatch','-W','.github/workflows/test.yml','-P','ubuntu-24.04='+pins['images']['runner'],
            '--container-architecture','linux/amd64','--network','pg-extensions-e2e'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,check=True)
    check_renovate(acceptance/'renovate',pins)
    run_fixtures(acceptance/'fixtures',pins,args.output/'cosign.key',args.output/'cosign.pub')
    inventory=discover();cases=[]
    # Dockerfile checks run on amd64 and use cache-only output with annotations.
    generator=json.loads((acceptance/'fixtures/result.json').read_text())['generator']
    check_builder='pgrx-check-'+uuid.uuid4().hex[:16]
    subprocess.run(['docker','buildx','create','--name',check_builder,'--driver','docker-container','--driver-opt','image='+pins['images']['buildkit']],check=True)
    try:
        with (acceptance/'bake-check.log').open('w') as log:
            for extension in inventory:
                subprocess.run(['docker','buildx','bake','--builder',check_builder,'-f','docker-bake-pgrx.hcl','-f',extension+'/metadata.hcl',
                    '--check','--set','*.platform=linux/amd64','--set','*.output=type=cacheonly'],cwd=ROOT,
                    env={**os.environ,'sbom_generator':generator,'build_timestamp':'2000-01-01T00:00:00Z'},stdout=log,stderr=subprocess.STDOUT,check=True)
    finally:subprocess.run(['docker','buildx','rm',check_builder],check=True)

    if source_digest()!=initial_source:raise ValueError('source changed during native preflight')
    for extension,metadata in inventory.items():
        for distro,versions in metadata['versions'].items():
            for major in versions:
                # Select by the real Bake PG argument instead of deriving target names.
                env={**os.environ,'DISTRO':distro,'build_timestamp':'2000-01-01T00:00:00Z',
                     'sbom_generator':'example.invalid/generator@sha256:'+'0'*64}
                definition=json.loads(subprocess.check_output(['docker','buildx','bake','-f','docker-bake-pgrx.hcl','-f',extension+'/metadata.hcl','--print'],cwd=ROOT,env=env))
                targets=[name for name,value in definition['target'].items() if value['args']['PG_MAJOR']==major]
                if len(targets)!=1:raise ValueError('ambiguous metadata target: '+extension+'/'+distro+'/'+major)
                case=invoke_case(extension,distro,args.output,pins,secrets,target=targets[0],cnpg_version=cnpg_version)
                destination=acceptance/'cases'/case.name
                extract_artifacts(case,destination)
                cases.append(reconcile(destination,extension,distro,major,['linux/amd64']))
    if source_digest()!=initial_source:raise ValueError('source changed during native acceptance')
    report=write_receipt(acceptance,cases,dict.fromkeys(['contracts','go','actionlint','act_unit','fixtures','renovate'],True))
    print(report)

if __name__=='__main__':main()
