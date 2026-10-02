#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
mkdir -p "$TEST_OUTPUT"
extension_sql="${PG_EXTENSION_PAYLOAD:?PG_EXTENSION_PAYLOAD is required}/share/extension/pgtap.sql"
if [ ! -r "$extension_sql" ]; then
  echo "mounted pgTAP image payload is missing $extension_sql" >&2
  exit 1
fi
cp "$extension_sql" upstream/sql/pgtap.sql
cd upstream
exec "$PG_REGRESS" --inputdir="test" --expecteddir="test" --schedule="test/schedule/main.sch" --schedule="test/build/run.sch" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE"
