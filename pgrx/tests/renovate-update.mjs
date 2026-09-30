// Execute inside the pinned Renovate image. Only /tmp is writable.
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { extractPackageFile } from '/usr/local/renovate/dist/modules/manager/custom/regex/index.js';
import { doAutoReplace } from '/usr/local/renovate/dist/workers/repository/update/branch/auto-replace.js';
import { GlobalConfig } from '/usr/local/renovate/dist/config/global.js';

GlobalConfig.set({ localDir: '/tmp/renovate-update-fixture' });
const config = JSON.parse(await fs.readFile('/repo/renovate.json', 'utf8'));
const sourcePins = JSON.parse(await fs.readFile('/repo/pgrx/dependencies/sources.json', 'utf8'));
const cases = [
  ...Object.keys(sourcePins).map(name => [name + '/metadata.hcl', 'PGRX source tags']),
  ...['tools', 'workflow-tools'].map(name => ['pgrx/dependencies/' + name + '.json', 'PGRX workflow/build tool']),
  ['pgrx/dependencies/workflow-tools.json', 'PGRX digest-pinned'],
  ['pgrx/dependencies/bases.json', 'PGRX base indexes'],
  ['pgrx/dependencies/fixtures/lock.json', 'PGRX CNPG operator/catalog'],
  ['.github/workflows/pgrx_targets.yml', 'updates the Taskfile'],
];
let count = 0;
for (const [packageFile, prefix] of cases) {
  const manager = config.customManagers.find(value => value.description.startsWith(prefix));
  assert(manager, prefix);
  const content = await fs.readFile('/repo/' + packageFile, 'utf8');
  const extracted = extractPackageFile(content, packageFile, manager);
  assert(extracted?.deps.length, packageFile);
  for (const [depIndex, dependency] of extracted.deps.entries()) {
    if (prefix === 'updates the Taskfile' && dependency.depName !== 'ghcr.io/cnpg-extensions/cnpg-sbom-generator') continue;
    const change = dependency.currentDigest
      ? { newDigest: (dependency.currentDigest.startsWith('sha256:') ? 'sha256:' : '') + 'a'.repeat(dependency.currentDigest.replace('sha256:', '').length) }
      : { newValue: dependency.currentValue.startsWith('v') ? 'v999.0.0' : '999.0.0' };
    const updated = await doAutoReplace({ ...manager, ...extracted, ...dependency, ...change,
      manager: 'regex', packageFile, depIndex }, content, false);
    assert.notEqual(updated, content, dependency.depName);
    const reextracted = extractPackageFile(updated, packageFile, manager).deps[depIndex];
    assert.equal(reextracted.currentValue, change.newValue ?? dependency.currentValue);
    assert.equal(reextracted.currentDigest, change.newDigest ?? dependency.currentDigest);
    if (packageFile.endsWith('/metadata.hcl')) {
      assert.deepEqual(updated.match(/sql\s*=\s*"[^"]+"/g), content.match(/sql\s*=\s*"[^"]+"/g));
    }
    // A version proposal must leave checksum refresh to its explicit owner.
    if (change.newValue && packageFile.endsWith('.json')) {
      assert.deepEqual(updated.match(/"sha256":\s*"[a-f0-9]+"/g), content.match(/"sha256":\s*"[a-f0-9]+"/g));
    }
    count++;
  }
}
assert(count >= 25, 'incomplete Renovate update coverage');
console.log(JSON.stringify({ success: true, replacementsChecked: count }));
