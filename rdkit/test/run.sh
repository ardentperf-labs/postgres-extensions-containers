#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
mkdir -p "$TEST_OUTPUT"
cd upstream/Code/PgSQL/rdkit
PGOPTIONS="${PGOPTIONS:+$PGOPTIONS }-c extra_float_digits=0"
export PGOPTIONS
exec "$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" rdkit-91 props btree molgist bfpgist-91 bfpgin sfpgist slfpgist fps reaction
