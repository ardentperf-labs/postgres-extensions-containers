# PGRX extension builds

PGRX targets are discovered from `build_system = "pgrx"` in ordinary extension
metadata. Debian discovery and OS-library maintenance exclude those targets;
catalog and testing-value generation support both. Source tags remain literal
(including `v`), while SQL versions remain separate. Extension READMEs describe
usage; this directory contains build and validation internals.

Consumers use the shared [verification procedure](VERIFYING_IMAGES.md) for all
extension images.

## Build and evidence contract

The extension Dockerfiles retain their attributed upstream build commands.
`install-pgrx-build-environment.sh` installs exact apt artifacts, the locked Rust
distribution, the cargo-pgrx source matching the upstream Cargo lock, and pinned
reporting tools. It applies the existing JWT patch only to its declared release.
Cargo-about and cargo-cyclonedx use SHA-256-verified release binaries on both
architectures, with no source-build fallback. Only cargo-pgrx is built from its
locked source archive. All locked crate sources are fetched before offline
reporting because cargo-about queries metadata before applying its target filter.
No helper silently rewrites source versions or updates Cargo dependencies.

The post-build finalizer resolves target-filtered Cargo metadata using the same
package, PostgreSQL feature, non-PG defaults, and feature policy as cargo-pgrx.
It emits CycloneDX and cargo-about reports, checks Cargo.lock for drift, ships
license texts, and hashes the finished library/control/SQL payload. The manifest
is written last. The diagnostic `pgrx-sbom` target exports these reports; it does
not replace an attestation-producing image build.

The published, digest-pinned CNPG generator runs unchanged. Its API-v1 hook reads
hashed reports from the builder mount, verifies target and source identity,
cross-checks CycloneDX identities, excludes build/dev and proc-macro-only edges,
and binds the reported root to identical final payload bytes and ELF machine.
Runtime features propagate from the selected root through active dependencies;
weak optional feature references do not activate unused backends or leak their
features into shared crates. Cargo metadata supplies full package identities;
retained dependency conditions are evaluated against `rustc --print cfg` for
the selected target. Generated Python bytecode is excluded from Docker
contexts so local reporting caches cannot change the copied helper code.
It preserves the generator's inventory, OS packages, checksums, and license
associations. Unknown license expressions remain `NOASSERTION`; shipped text is
retained and associated by full Cargo identity. cargo-about 0.9.2's repeated,
identical Boolean `doctest` field is normalized before report hashing. Other
duplicate JSON keys and conflicting values are rejected.

Preparation freezes the source snapshot, timestamp, generator, bases, targets,
and definitions for a logical workflow run. Every native platform job builds
one target on its matching architecture. It exports a complete OCI layout and a
record bound to that preparation. Assembly rejects missing or unexpected records,
validates their raw graphs, and uses full staging-index references in Buildx's
dry-run merge. Normal tags are assigned only after reading back a valid candidate.

Sign, security, smoke, and promotion consume per-target assembly artifacts.
Production promotion is restricted to trusted `main` push/dispatch events.
Trivy reports vulnerabilities and licenses; findings are retained for review,
while scanner errors fail the job. CNPG smoke uses pinned operator/catalog
fixtures and the shared Task/Dagger tests, then checks mounted-library hashes,
ELF architecture, dynamic-library resolution, SQL version, preload settings,
and the pg-durable worker's connection to `app`. The shared finalizer additionally
stages Bookworm/amd64's required quadmath library and copyright for pg-search;
the existing OpenBLAS and Fortran copies remain in the recipe.

## Local validation

Run from the repository root on a native amd64 Docker host with `act`, Docker
Buildx, Go, and Python available. The harness installs its checksum-pinned tools.
It uses a dedicated Docker network, two local registries, disposable signing
keys, and a separate Kind/Dagger test environment. It may add local registry
container addresses to `/etc/hosts`. Outputs and keys stay outside the checkout.

```sh
task pgrx:test
python3 pgrx/refresh_lock.py --check
task pgrx:native -- --output /tmp/pgrx-native-run
```

The native command runs the actual unit workflow through `act`, contract and Go
tests, actionlint, Renovate extraction, native generator/consumer fixtures, and
every metadata-declared extension/distro/PG case through the top-level PGRX
workflow and its reusable workflow. All job containers and BuildKit workers are
amd64. Each case must pass artifacts, assembly, signing, security, CNPG smoke,
and the destination-registry copy. A receipt is written only after independently
reconciling all downloaded artifacts and their hashes.

For diagnosis, run one actual workflow without producing a native gate receipt:

```sh
python3 pgrx/local/validate.py case --extension pg-session-jwt \
  --distro trixie --output /tmp/pgrx-jwt-case
```

Only after native validation passes, run the bounded final logical workflow:

```sh
task pgrx:multiplatform -- --extension pg-session-jwt --distro trixie \
  --native-report /tmp/pgrx-native-run/acceptance/native-report.json \
  --output /tmp/pgrx-final-run
```

That command validates the receipt against the current source and retained
artifacts before enabling the pinned ARM emulator. It builds only session-jwt,
Trixie, PG18, with amd64 and arm64 children. Every act job remains amd64, CNPG
loads the amd64 child, and both children retain independent SPDX/provenance and
are verified again after copying. Any source change invalidates the receipt.

A failed build keeps its uniquely named BuildKit builder for diagnosis. Successful
builds remove theirs. Remove only builders/containers belonging to your run when
reclaiming disk. Do not prune unrelated Docker state. Hosted native ARM capacity,
OIDC, and public publishing require a separate rollout check.

## Dependency updates

All lock material lives in `dependencies/`. Renovate proposes source tags, tool
versions, image digests, and operator/catalog commits. Coupled updates are not
automerged. Before merging, refresh the affected children and run the checks:

```sh
python3 pgrx/refresh_lock.py --refresh --only sources
python3 pgrx/refresh_lock.py --refresh --only tools
python3 pgrx/refresh_lock.py --refresh --only bases
python3 pgrx/refresh_lock.py --refresh --only fixtures
python3 pgrx/refresh_lock.py --check
```

Use only the refresh command relevant to the update. A source refresh binds the
tag, resolved commit, archive, upstream Cargo.lock, cargo-pgrx version, and CLI
crate checksum together. Review SQL version and upstream recipe changes manually.
Tool refreshes update both architectures and the full Rust distribution manifest.
The reporting-tool lock owns the hook's embedded SPDX identifier list; update that
list from cargo-about's locked `spdx` crate when upgrading its license parser.

Base-index updates own the platform-child and apt-artifact refresh. `refresh_apt.py`
uses native amd64 apt for both architectures; ARM base package status is recovered
from the pinned base SPDX and signed apt indexes. It does not execute ARM code.
The apt ownership record binds all four artifact lists to the base lock. Each
build verifies downloaded SHA256 values and disables repository fallback during
installation. An unavailable old artifact requires an explicit lock refresh.

The runner image owns Python, Docker CLI and Buildx used inside act. The shared
Taskfile owns the already pinned Kubernetes node and kubectl, and the shared
Dagger test function owns Chainsaw. PGRX overrides replace the mutable toolbox
installer with the pinned runner plus the checked Kind binary. No PGRX path
reinstalls unpinned apt/apk tools during smoke testing.

Keep upstream recipe URL comments immediately above build commands. Add a source
lock and recipe configuration for a new extension, refresh required system
artifacts, and extend the native matrix by metadata. Do not add a second SBOM
composer or a build-system-specific consumer interface.
