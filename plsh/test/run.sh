#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

set -- init function trigger crlf psql
if [ "$PG_MAJOR" -ge 9 ]; then set -- "$@" inline; fi
if [ "$PG_MAJOR" -ge 10 ]; then set -- "$@" event_trigger; fi
"$PG_REGRESS" --inputdir="test" --expecteddir="test" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" "$@"
