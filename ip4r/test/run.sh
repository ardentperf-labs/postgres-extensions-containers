#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

set -- ip4r
if [ "$PG_MAJOR" -ge 11 ]; then set -- "$@" ip4r-v11; fi
if [ "$PG_MAJOR" -ge 16 ]; then set -- "$@" ip4r-softerr; fi
"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" "$@"
