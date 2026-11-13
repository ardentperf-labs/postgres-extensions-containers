const {test} = require('node:test');
const assert = require('node:assert/strict');
const {versionOnly} = require('./update-policy.cjs');
test('PGRX complete version pair, with no command or target changes', () => {
  const before = '# renovate: datasource=github-tags depName=owner/source versioning=semver\npackage = "v1.2.3"\nsql = "1.2.3"\n';
  const after = before.replaceAll('1.2.3', '1.2.4');
  assert.ok(versionOnly('pgrx/example/metadata.hcl', before, after));
  assert.ok(!versionOnly('pgrx/example/metadata.hcl', before, after + 'source_repository = "evil"\n'));
  assert.ok(!versionOnly('pgrx/example/metadata.hcl', before, after.replace('sql = "1.2.4"', 'sql = "2.0"')));
  assert.ok(!versionOnly('pgrx/example/metadata.hcl', before, after.replaceAll('1.2.4', '1.3.0-rc1')));
});
test('Debian package and verified SQL extraction change together', () => {
  const before = '// renovate: suite=trixie-pgdg depName=postgresql-18-example\npackage = "1.2.0-1.pgdg13+1"\n// renovate: suite=trixie-pgdg depName=postgresql-18-example extractVersion=^(?<version>\\d+\\.\\d+)\nsql = "1.2"\n';
  assert.ok(versionOnly('example/metadata.hcl', before, before.replaceAll('1.2', '1.3')));
  assert.ok(!versionOnly('example/metadata.hcl', before, before.replace('sql = "1.2"', 'sql = "9.9"')));
  assert.ok(!versionOnly('source-build/fixture/metadata.hcl', before, before.replaceAll('1.2', '1.3')));
});

test('mixed bot changes need current-head admin approval; stale events fail closed', async () => {
  const {check} = require('./update-policy.cjs');
  const sha = 'a'.repeat(40);
  const pr = {number: 1, head: {sha}, base: {sha: 'b'.repeat(40)}, user: {type: 'Bot', login: 'renovate[bot]'}};
  let reviews = [], permission = 'write', posted, failed;
  const github = {
    paginate: async method => method === 'reviews' ? reviews : [],
    rest: {
      pulls: {get: async () => ({data: {...pr, changed_files: 1}}), listCommits: 'commits', listFiles: 'files', listReviews: 'reviews'},
      repos: {getCollaboratorPermissionLevel: async () => ({data: {permission}}), createCommitStatus: async value => {posted = value;}},
    },
  };
  const context = {repo: {owner: 'project', repo: 'extensions'}, payload: {pull_request: pr}};
  const core = {setFailed: message => {failed = message;}};
  reviews = [{user: {login: 'maintainer'}, state: 'APPROVED', commit_id: sha}];
  await check({github, context, core});
  assert.equal(posted.state, 'failure');
  assert.ok(failed);
  permission = 'admin';
  await check({github, context, core});
  assert.equal(posted.state, 'success');
  reviews.push({user: {login: 'maintainer'}, state: 'DISMISSED', commit_id: sha});
  await check({github, context, core});
  assert.equal(posted.state, 'failure');
  github.rest.pulls.get = async () => ({data: {...pr, head: {sha: 'c'.repeat(40)}}});
  await assert.rejects(check({github, context, core}), /Stale/);
});
