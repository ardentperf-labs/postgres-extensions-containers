# Universe source builds

Recipes whose dependency burden makes Debian packaging prohibitive live here.
Ordinary extensions should use Debian packaging; PGRX extensions use `pgrx/`.
Use shared `source-build/` orchestration, native AMD64/ARM64 compilation, and the
shared digest-pinned SBOM generator. See the [canonical design review](https://github.com/ardentperf-labs/postgres-extensions-containers/issues/3)
and [pg-duckdb pilot](pg-duckdb/README.md). Inclusion requires dependency review,
accurate shipped-component identities, and shared acceptance checks.
