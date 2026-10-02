#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
if [ "${PG_MAJOR:-}" != 18 ]; then echo "Unsupported: vendored upstream PL tests are from PostgreSQL 18.6; PG_MAJOR=18 is required" >&2; exit 77; fi
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="src/pl/tcl" --expecteddir="src/pl/tcl" --load-extension=pltcl --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" pltcl_setup pltcl_queries pltcl_trigger pltcl_call pltcl_start_proc pltcl_subxact pltcl_unicode pltcl_transaction
