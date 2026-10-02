#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

PGDATABASE=regression
export PGDATABASE
"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" pgq_node_init_ext pgq_node_test
