#!/bin/sh
set -eu
: "${PG_REGRESS:=pg_regress}"
: "${TEST_OUTPUT:=$PWD/results}"
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="." --expecteddir="." --dbname="${PGDATABASE:-regression}" --outputdir="$TEST_OUTPUT" init-extension function json jsonb json_conv types bytea context cursor array_spread plv8_regressions memory_limits inline composites trigger procedure find_function start_proc window regressions
