#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

PGDATABASE=regression
export PGDATABASE
"$PG_REGRESS" --inputdir="test" --expecteddir="test" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" plproxy_init plproxy_test plproxy_select plproxy_many plproxy_errors plproxy_clustermap plproxy_dynamic_record plproxy_encoding plproxy_split plproxy_target plproxy_alter plproxy_cancel plproxy_range plproxy_sqlmed plproxy_table plproxy_modular
