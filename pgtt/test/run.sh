#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

"$PG_REGRESS" --inputdir="test" --expecteddir="test" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" 00_init 01_oncommitdelete 02_oncommitpreserve 03_createontruncate 04_rename 05_useindex 06_createas 07_createlike 08_plplgsql 09_transaction 10_foreignkey 11_after_error 12_droptable 13_searchpath 14_concurrent_index 15_security_grants 16_sql_injection 17_drop_authorization 18_subquery 19_trigger
