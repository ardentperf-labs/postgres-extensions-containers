// Executed only from the protected base checkout; never import PR code.
const stable = value => /^v?[0-9][0-9A-Za-z.+:_-]*$/.test(value) && !/(alpha|beta|rc|~)/i.test(value);

function versionOnly(path, before, after) {
  if (!/^(?:[^/]+|pgrx\/[^/]+|universe\/[^/]+)\/metadata\.hcl$/.test(path)) return false;
  const normalize = text => {
    const lines = text.split('\n');
    let changes = 0;
    const majors = [];
    for (let i = 0; i < lines.length; i++) {
      const match = lines[i].match(/^(\s*)(package|sql)(\s*=\s*)"([^"]+)"(\s*)$/);
      if (!match) continue;
      const annotation = lines[i-1] || '';
      const source = /renovate: datasource=(github-tags|gitlab-tags|git-tags) depName=\S+ versioning=semver/.test(annotation);
      const debian = /renovate: suite=\S+ depName=\S+/.test(annotation);
      if (!stable(match[4]) || (!source && !debian)) continue;
      // Only reviewed source-to-SQL mappings qualify. Universe is initially
      // manual until its mapping is verified against shipped control files.
      if (source && !path.startsWith('pgrx/')) continue;
      if (source) {
        const sql = (lines[i+1] || '').match(/^(\s*sql\s*=\s*)"([^"]+)"(\s*)$/);
        if (!sql || sql[2] !== match[4].replace(/^v/, '')) continue;
        lines[i+1] = sql[1] + '"<version>"' + sql[3];
      }
      // Independent SQL updates require a reviewed extraction rule.
      if (match[2] === 'sql') {
        const extraction = annotation.match(/extractVersion=(\S+)/)?.[1];
        const dependency = annotation.match(/depName=(\S+)/)?.[1];
        if (!extraction || !dependency) continue;
        let packageValue;
        for (let j = i - 1; j >= 1; j--) {
          if (lines[j - 1].includes('depName=' + dependency)) {
            const candidate = text.split('\n')[j].match(/^\s*package\s*=\s*"([^"]+)"/);
            if (candidate) { packageValue = candidate[1]; break; }
          }
        }
        try {
          if (!packageValue || new RegExp(extraction).exec(packageValue)?.groups?.version !== match[4]) continue;
        } catch { continue; }
      }
      lines[i] = match[1] + match[2] + match[3] + '"<version>"' + match[5];
      majors.push(match[4].replace(/^\d+:/, '').match(/^v?(\d+)/)?.[1]);
      changes++;
    }
    return {text: lines.join('\n'), changes, majors};
  };
  const a = normalize(before), b = normalize(after);
  return a.changes > 0 && a.changes === b.changes && a.text === b.text && JSON.stringify(a.majors) === JSON.stringify(b.majors);
}

async function check({github, context, core}) {
  const pr = context.payload.pull_request;
  const {data: current} = await github.rest.pulls.get({...context.repo, pull_number: pr.number});
  if (current.head.sha !== pr.head.sha) throw new Error('Stale update-policy event');
  let allowed = pr.user.type !== 'Bot';
  if (!allowed) {
    const commits = await github.paginate(github.rest.pulls.listCommits, {...context.repo, pull_number: pr.number});
    const renovate = pr.user.login === 'renovate[bot]' && current.performed_via_github_app?.slug === 'renovate' && commits.length > 0 && commits.every(c => c.author?.login === 'renovate[bot]' && c.commit.verification?.verified);
    const files = await github.paginate(github.rest.pulls.listFiles, {...context.repo, pull_number: pr.number, per_page: 100});
    // GitHub caps this API at 3000 files: fail closed on incomplete diffs.
    if (renovate && files.length === current.changed_files && files.length < 3000) {
      allowed = files.length > 0;
      for (const file of files) {
        if (file.status !== 'modified') { allowed = false; break; }
        const read = async ref => {
          const {data} = await github.rest.repos.getContent({...context.repo, path: file.filename, ref});
          if (data.type !== 'file' || data.encoding !== 'base64') throw new Error('Unsupported diff content');
          return Buffer.from(data.content, 'base64').toString('utf8');
        };
        if (!versionOnly(file.filename, await read(pr.base.sha), await read(pr.head.sha))) { allowed = false; break; }
      }
    }
    if (!allowed) {
      // Unknown/mixed bot changes need current-head project-admin review;
      // native CODEOWNERS remains the human review boundary.
      const reviews = await github.paginate(github.rest.pulls.listReviews, {...context.repo, pull_number: pr.number});
      const latest = new Map();
      for (const review of reviews) if (review.state !== 'COMMENTED') latest.set(review.user.login, review);
      for (const [username, review] of latest) {
        if (review.state !== 'APPROVED' || review.commit_id !== pr.head.sha || username === pr.user.login) continue;
        const {data} = await github.rest.repos.getCollaboratorPermissionLevel({...context.repo, username});
        if (data.permission === 'admin') { allowed = true; break; }
      }
    }
  }
  await github.rest.repos.createCommitStatus({...context.repo, sha: pr.head.sha,
    context: 'Update policy', state: allowed ? 'success' : 'failure',
    description: allowed ? 'Version-only update or current-head project review' : 'Mixed or unverified bot update requires project-admin review'});
  if (!allowed) core.setFailed('Project-admin review required for this bot update');
}
module.exports = {versionOnly, check};
