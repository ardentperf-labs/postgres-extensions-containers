#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

set -- extension tables unit binary unicode prefix units time temperature functions language_functions round derived compare aggregate iec custom
if [ "$PG_MAJOR" -ge 10 ]; then set -- "$@" crosstab convert; fi
"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" "$@"
