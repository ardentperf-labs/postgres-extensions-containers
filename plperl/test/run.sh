#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
if [ "${PG_MAJOR:-}" != 18 ]; then echo "Unsupported: vendored upstream PL tests are from PostgreSQL 18.6; PG_MAJOR=18 is required" >&2; exit 77; fi
tests="plperl_setup plperl plperl_lc plperl_trigger plperl_shared plperl_elog plperl_unicode plperl_util plperl_init plperlu plperl_array plperl_call plperl_transaction plperl_env"
if command -v perl >/dev/null 2>&1 && perl -V:usemultiplicity 2>/dev/null | grep -q "usemultiplicity='define';"; then tests="$tests plperl_plperlu"; fi
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="src/pl/plperl" --expecteddir="src/pl/plperl" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" $tests
