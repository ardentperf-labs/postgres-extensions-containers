#!/bin/sh
set -eu
: "${PG_REGRESS:=pg_regress}"
: "${TEST_OUTPUT:=$PWD/results}"
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="test" --expecteddir="test" --dbname="${PGDATABASE:-regression}" --outputdir="$TEST_OUTPUT" init test unicode
