#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
if [ "${PG_MAJOR:-}" != 18 ]; then echo "Unsupported: vendored upstream PL tests are from PostgreSQL 18.6; PG_MAJOR=18 is required" >&2; exit 77; fi
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="src/pl/plpython" --expecteddir="src/pl/plpython" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" plpython_schema plpython_populate plpython_test plpython_do plpython_global plpython_import plpython_spi plpython_newline plpython_void plpython_call plpython_params plpython_setof plpython_record plpython_trigger plpython_types plpython_error plpython_ereport plpython_unicode plpython_quote plpython_composite plpython_subtransaction plpython_transaction plpython_drop
