# Approved extension batch

The project owner approved all 67 candidates in this batch. Proposal issues and
CloudNativePG upstream governance requirements do not apply. Technical packaging,
redistribution, functional validation and CNPG Extensions registration requirements
remain applicable. No production images may be published by this work.

The owner subsequently requested delivery as a review branch in
`ardentperf-labs/postgres-extensions-containers`, without an upstream PR.
Local technical validation remains required.

## Scope and evidence

`tracking.json` is the candidate-to-image inventory and validation ledger.
`pgdg-audit-baseline.json` preserves the supplied PGDG discovery audit, dated
2026-09-29. It is historical discovery evidence, not proof of the new image builds
or CNPG tests. Per-image evidence records must distinguish those checks.

Excluded: bgw_replstatus, pg_catcheck, pg_checksums, pg_auto_failover, repmgr,
pgpool_adm, pgpool_recovery, pg_fact_loader, pgl_ddl_deploy, pglogical_ticker,
omnidb_plpgsql_debugger, slony1-2 and Multicorn. Deferred: oracle_fdw and
pgauditlogtofile. address_standardizer is already included upstream in PostGIS;
pg_failover_slots is included in the standard PostgreSQL image.

## Execution baseline

- Base revision: `f0bd1ad` (matches fetched `origin/main` on 2026-09-29).
- Working branch: `dev/approved-extension-batch`; original working tree clean.
- `task prereqs`: PASS.
- Baseline `task checks:all`: PASS for all 29 existing image directories.
- Latest stable requirement rechecked on 2026-09-29:
  [PostgreSQL 18.6](https://www.postgresql.org/support/versioning/) and
  [Debian 13 Trixie](https://www.debian.org/releases/). PostgreSQL 19 remains beta.
- Existing image coverage rechecked against the current GitHub trees of
  [CNPG Extensions](https://github.com/cnpg-extensions/postgres-extensions-containers),
  [CloudNativePG](https://github.com/cloudnative-pg/postgres-extensions-containers)
  and [CNPG Extensions catalogs](https://github.com/cnpg-extensions/artifacts/tree/main/image-catalogs-extensions).
  No approved candidate duplicates an existing extension image.
- Intended preferred matrix: PG18 × {Trixie, Bookworm} × {amd64, arm64}.
  Package availability gaps must be represented by absent metadata combinations,
  not skipped tests for advertised combinations.
- Per-candidate completion and test outcomes are recorded in [tracking.md](tracking.md)
  and [tracking.json](tracking.json). Delivery is the review branch; no upstream PR
  is requested.

## Validation protocol

For each image run `task e2e:test:full TARGET=<image> DISTRO=trixie` and repeat
with `DISTRO=bookworm` when supported. Docker Bake builds both architectures.
Record runtime coverage separately; the host is amd64. Serialize tests within each Kind/registry environment; independent runs use
isolated clusters, registries, checkouts and Dagger engines. Capture exact image tags/digests and tested revision. Validate
README declarative setup as well as target-specific behavior. Finish with
`task checks:all` and `task e2e:cleanup`.

README examples are also applied to Kind with
[`tools/validate-readme.py`](tools/validate-readme.py). After a target's full local
workflow builds its image and dependencies, run:

```sh
python3 docs/approved-batch/tools/validate-readme.py <image> \
  --registry registry.pg-extensions:5000 \
  --registry-http http://localhost:5000 \
  --kubeconfig <external-kubeconfig> \
  --output <result.json>
```

The checker creates an isolated namespace, substitutes local testing image
references pinned to their resolved digests, and applies the README's complete
resources. It waits for Cluster readiness, successful Database extension
reconciliation and any installer Job, then deletes the namespace. Results record
the README hash and image digests. This complements the functional Chainsaw
fixtures; it does not replace them. All three test environments have separate registries, host ports, kubeconfigs,
checkouts and Dagger engines.

## Integration decisions

All 67 additions use PGDG packages and PostgreSQL 18. The package indexes do not
provide PG18 Bookworm builds for DocumentDB, mongo_fdw, pg_gvm or RDKit; those four
images advertise Trixie only. The remaining 63 advertise both suites. This is
130 PostgreSQL/distribution combinations and 260 architecture builds. Runtime
validation uses amd64 Kind nodes; an arm64 runtime environment is unavailable.

The inventory records candidates that supply several SQL extensions, including
language transforms. Bucardo supplies server SQL and uses a separate installer
Job and replication daemon; it is not represented as a CREATE EXTENSION module.
Decoderbufs supplies a logical decoding plugin; pgextwlist and pg_rage_terminator
supply preload modules. Their fixtures verify the module behavior without
claiming CREATE EXTENSION support. The language images include their
runtimes, native dependency closures and package notices. Images that redistribute
copyleft dependencies also retain exact corresponding source archives. Per-image
READMEs describe privileges, optional file-feature limits and supported clients.

The dependency resolver orders local image prerequisites, separates SQL-only
prerequisites supplied by the base or the same image, and supports catalog image
names that differ from their SQL names. Local and CI workflows build prerequisites
before testing dependents. [BUILD.md](../../BUILD.md) documents the metadata syntax.
Focused regression runs cover existing HypoPG, pg_stat_kcache and MobilityDB images.
Failure-injection checks also verify that dependency resolution fails before
any build when the local Task command or CI JSON parsing fails; see the
`dependency-*-failure-check.json` records.

Runtime result files under each image's `evidence/runtime/` record commands,
immutable image and architecture digests, and hashes of the tested source files.
The recorded base Git revision identifies the starting revision; the additions
were tested before the single final commit. README deployment results record their
own content hash and resolved image digests. These records distinguish actual
operator tests from earlier package inspection and standalone SQL smoke tests.

Earlier successful runs retain the shared-tooling and README hashes actually
used at the time. Later README edits are covered by the separately hashed README
deployments. The final dependency-tooling changes are covered by Go unit tests,
Task/workflow failure-injection checks and both-suite regressions for the three
existing targets above; historical result hashes are not rewritten.

DocumentDB ships its main/core and extended-RUM components. Distributed
DocumentDB artifacts are omitted: their Citus prerequisite has no PG18 package
in the checked PGDG Trixie repository, and this catalog has no compatible Citus
image. Supporting that mode requires a compatible dependency image and its own
integration tests. The separate Mongo wire-protocol gateway is outside this batch.

The generic catalog check uses the CNPG administrator Secret: DocumentDB restricts
its schema before an application role is granted DocumentDB privileges, which can
also prevent that role from planning a catalog-filter query. Target-specific
fixtures separately exercise the documented application privileges and behavior.

DocumentDB SQL operations that open internal connections are tested in a session
authenticated as `postgres`, with `SET ROLE app` for effective application
privileges. Internal connections use CNPG's Unix socket and existing peer
authentication. Direct application-authenticated sessions need separately
provisioned internal credentials and are not supported by this example. See the
[DocumentDB README](../../documentdb/README.md) for the explicit boundary.

MongoDB FDW retains the PGDG extension binary and rebuilds its exact Debian
`mongo-c-driver` dependency with a one-line argument-order correction. The
original Debian security validation remains enabled. The source archives, patch
and build accounting are shipped in the image; the build rejects unreviewed
driver source versions. See [MongoDB FDW evidence](../../mongo-fdw/evidence.md).

## Final local validation

[Final validation](final-validation.json) records all 67 additions passing 130
PG18/distribution runtime combinations on amd64, 260 amd64/arm64 image builds,
and 67 actual README deployments. All 123 README Cluster/Database manifest blocks
passed live schema validation. Final repository checks passed for all 96 targets;
Go unit tests, six existing-target regression runs and dependency failure-injection
checks passed. An arm64 runtime environment was unavailable.

[Cleanup evidence](cleanup.json) records removal of all three task-owned Kind,
registry, Dagger-engine and network environments after evidence collection.
Branch CI results are reported with delivery; local results do not assert that
remote CI has completed.
