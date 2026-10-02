#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" test1 test2 test3 test4
