#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

set -- create_extension prefix falcon
if [ "$PG_MAJOR" -ge 9 ]; then set -- "$@" explain; fi
set -- "$@" queries
"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" "$@"
