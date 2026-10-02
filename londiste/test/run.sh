#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

PGDATABASE=regression
export PGDATABASE
export LANG=C.UTF-8
"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" init_ext londiste_provider londiste_subscriber londiste_fkeys londiste_execute londiste_seqs londiste_merge londiste_leaf londiste_create_part londiste_merge_fkeys
