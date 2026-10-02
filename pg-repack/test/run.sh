#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
if [ -n "${PG_EXTENSION_PAYLOAD:-}" ]; then PATH="$PG_EXTENSION_PAYLOAD/bin:$PG_EXTENSION_PAYLOAD/usr/bin:$PATH"; fi
export PATH
if [ "$PGDATABASE" != "contrib_regression" ]; then
  echo "pg-repack upstream SQL invokes pg_repack --dbname=contrib_regression; set PGDATABASE=contrib_regression" >&2
  exit 77
fi
command -v pg_repack >/dev/null 2>&1 || { echo "pg-repack native suite requires pg_repack client on PATH" >&2; exit 77; }
mkdir -p "$TEST_OUTPUT"
"$PWD/setup-tablespaces.sh"
cd upstream
exec "$PG_REGRESS" --inputdir="regress" --expecteddir="regress" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" init-extension repack-setup repack-run error-on-invalid-idx no-error-on-invalid-idx after-schema repack-check nosuper tablespace get_order_by trigger
