"""Native gate receipts are reconciled from actual workflow artifact contents."""
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

from record import load_preparation, validate_record
from verify import validate_layout, safe_file
from workflow import discover, source_digest


def file_digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract_artifacts(case, destination):
    archives = sorted((case / 'artifacts').rglob('*.zip'))
    names = [archive.stem for archive in archives]
    if not archives or len(names) != len(set(names)):
        raise ValueError('missing or duplicate act artifact archives')
    destination.mkdir(parents=True, exist_ok=False)
    for archive in archives:
        target = destination / archive.stem
        target.mkdir()
        with zipfile.ZipFile(archive) as source:
            paths = set()
            for entry in source.infolist():
                relative = Path(entry.filename)
                if relative.is_absolute() or '..' in relative.parts or entry.filename in paths or (entry.external_attr >> 16) & 0o170000 == 0o120000:
                    raise ValueError('unsafe artifact ZIP member')
                paths.add(entry.filename)
            source.extractall(target)
    shutil.copyfile(case / 'act.log', destination / 'act.log')
    shutil.copyfile(case / 'command.json', destination / 'command.json')


def reconcile(directory, extension, distro, major, platforms):
    preparation_dir = directory / ('prepared-' + extension)
    preparation = load_preparation(preparation_dir)
    if preparation['extension'] != extension or preparation['platforms'] != platforms or len(preparation['targets']) != 1:
        raise ValueError('unexpected native case preparation')
    target, settings = next(iter(preparation['targets'].items()))
    selector=preparation['inputs'].get('cnpg_version') or 'main'
    expected_directories={'prepared-'+extension,'assemblies-'+extension,'assembly-'+target,
        'sign-'+target,'security-'+target,'smoke-'+target+'-'+selector,'promote-'+target}
    expected_directories.update('platform-'+extension+'-'+row['id'] for row in preparation['rows'])
    if {entry.name for entry in directory.iterdir() if entry.is_dir()} != expected_directories:
        raise ValueError('unexpected or missing workflow artifacts')
    if settings['distro'] != distro or settings['pg_major'] != major:
        raise ValueError('wrong native target')
    records = []
    for row in preparation['rows']:
        records.append(validate_record(preparation, row, directory / ('platform-' + extension + '-' + row['id'])))
    if len(records) != len(platforms):
        raise ValueError('unexpected native records')
    assembly_dir = directory / ('assembly-' + target)
    assembly = json.loads((assembly_dir / 'assembly.json').read_text())
    if assembly['preparation_sha256'] != preparation['preparation_sha256'] or assembly['platforms'] != platforms or assembly['run_id'] != preparation['run_id']:
        raise ValueError('assembly does not match preparation')
    graph = validate_layout(assembly_dir / 'layout', assembly['index_digest'], platforms)
    expected = sorted([d['digest'] for record in records for d in (record['runnable'], record['attestation'])])
    if sorted(d['digest'] for d in graph['index']['manifests']) != expected:
        raise ValueError('assembled descriptors differ from platform artifacts')
    for stage in ['sign', 'security', 'smoke', 'promote']:
        result_dir = directory / (stage + '-' + target + ('-'+selector if stage == 'smoke' else ''))
        result = json.loads((result_dir / 'result.json').read_text())
        if result != {'stage': stage, 'success': True, 'target': target, 'image': assembly['image'], 'run_id': preparation['run_id'], 'preparation_sha256': preparation['preparation_sha256']}:
            raise ValueError('missing or mismatched downstream result: ' + stage)
        if stage == 'security':
            for platform in platforms:
                report = result_dir / platform.split('/')[1]
                verification = json.loads((report / 'verification.json').read_text())
                if verification['image'] != assembly['image'] or verification['platform'] != platform or not verification['signature']:
                    raise ValueError('security verification mismatch')
                if json.loads((report / 'sbom.spdx.json').read_text()) != graph['platforms'][platform]['spdx']:
                    raise ValueError('security scanned another SPDX document')
                if not json.loads((report / 'trivy.json').read_text()):
                    raise ValueError('missing Trivy report')
        if stage == 'smoke':
            if json.loads((result_dir/'fixtures.json').read_text())['selector']!=selector:raise ValueError('smoke selector mismatch')
            runtime = json.loads((result_dir / 'runtime.json').read_text())
            if runtime['image'] != assembly['image'] or runtime['runnable_digest'] != graph['platforms']['linux/amd64']['descriptor']['digest'] or not runtime['libraries'] or runtime['sql_version_checked'] is not True:
                raise ValueError('runtime evidence does not match native child')
        if stage == 'promote':
            destination = json.loads((result_dir / 'destination.json').read_text())
            if destination['index_digest'] != assembly['index_digest'] or not destination['tags'] or any(not tag.startswith('registry-copy.pg-extensions:5000/') for tag in destination['tags']):
                raise ValueError('destination copy mismatch')
            for i in range(len(destination['tags'])):
                for platform in platforms:
                    copied = result_dir / ('copy-' + str(i) + '-' + platform.split('/')[1])
                    verified = json.loads((copied / 'verification.json').read_text())
                    if verified['index_digest'] != assembly['index_digest'] or not verified['signature']:
                        raise ValueError('destination signature or digest missing')
                    if json.loads((copied / 'sbom.spdx.json').read_text()) != graph['platforms'][platform]['spdx']:
                        raise ValueError('destination SPDX changed')
    return {'extension': extension, 'distro': distro, 'pg_major': major, 'run_id': preparation['run_id'],
            'image': assembly['image'], 'preparation_sha256': preparation['preparation_sha256'], 'success': True}


def write_receipt(directory, cases, fast_checks):
    files = {str(path.relative_to(directory)): file_digest(path) for path in sorted(directory.rglob('*')) if path.is_file()}
    report = {'schema_version': 1, 'complete': True, 'workspace_sha256': source_digest(),
              'cases': cases, 'fast_checks': fast_checks, 'files': files}
    path = directory / 'native-report.json'
    path.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
    verify_receipt(path, file_digest(path))
    return path


def verify_receipt(path, expected):
    if file_digest(path) != expected:
        raise ValueError('native receipt hash mismatch')
    report = json.loads(path.read_bytes())
    if report.get('schema_version') != 1 or report.get('complete') is not True or report.get('workspace_sha256') != source_digest():
        raise ValueError('native receipt is incomplete or stale')
    if report.get('fast_checks') != {'contracts': True, 'go': True, 'actionlint': True, 'act_unit': True, 'fixtures': True, 'renovate': True}:
        raise ValueError('required fast checks missing')
    for relative, expected_digest in report['files'].items():
        member = Path(relative)
        if member.is_absolute() or '..' in member.parts:
            raise ValueError('unsafe receipt path')
        file = safe_file(path.parent, relative)
        if file_digest(file) != expected_digest:
            raise ValueError('native evidence changed: ' + relative)
    inventory = discover()
    expected_cases = {(name, distro, major) for name, meta in inventory.items() for distro, versions in meta['versions'].items() for major in versions}
    cases = report.get('cases', [])
    if len(cases) != len(expected_cases) or {(c['extension'], c['distro'], c['pg_major']) for c in cases} != expected_cases:
        raise ValueError('native receipt does not cover all targets')
    for case in cases:
        actual = reconcile(path.parent / 'cases' / case['run_id'], case['extension'], case['distro'], case['pg_major'], ['linux/amd64'])
        if actual != case:
            raise ValueError('native case summary mismatch')
    return report
