#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" --schedule=parallel_schedule --encoding=UTF8 orafce orafce2 dbms_output dbms_utility files varchar2 nvarchar2 aggregates nlssort regexp_func dbms_sql
