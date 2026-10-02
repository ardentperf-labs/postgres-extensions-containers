#!/bin/sh
set -eu
: "${PG_REGRESS:=pg_regress}"
: "${TEST_OUTPUT:=$PWD/results}"
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="." --expecteddir="." --dbname="${PGDATABASE:-regression}" --outputdir="$TEST_OUTPUT" pg_statviz_test
