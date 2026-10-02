#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

if [ "$PG_MAJOR" -ge 10 ]; then set -- create_extension pre_prepare; else set -- create_module pre_prepare; fi
# Reproduce the source Makefile's generated DATA_built rule before REGRESS.
cp pre_prepare.sql pre_prepare--0.4.sql
"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" "$@"
