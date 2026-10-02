#!/bin/sh
set -eu
: "$PGDATABASE"; : "$TEST_OUTPUT"
command -v pg_prove >/dev/null 2>&1 || { echo "Mimeo upstream TAP suite requires pg_prove" >&2; exit 77; }
mkdir -p "$TEST_OUTPUT"
psql --set=ON_ERROR_STOP=1 --command='CREATE SCHEMA IF NOT EXISTS dblink; CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA dblink;'
psql --set=ON_ERROR_STOP=1 --command='CREATE EXTENSION IF NOT EXISTS pgtap;'
psql --set=ON_ERROR_STOP=1 --command='CREATE SCHEMA IF NOT EXISTS mimeo; CREATE EXTENSION IF NOT EXISTS mimeo WITH SCHEMA mimeo;'
cd upstream
exec pg_prove --dbname="$PGDATABASE" test/test01_setup.sql test/test02_setup_remote_tables.sql test/test03_run_maker_functions.sql test/test04_check_maker_data.sql test/test05_insert_remote_data_batch2.sql test/test06_run_refresh_functions.sql test/test07_check_refresh_data.sql test/test08_insert_remote_data_batch3.sql test/test09_check_refresh_data.sql test/test10_run_repull_tests.sql test/test11_test_individual_dml_types.sql test/test80_error_tests.sql test/test81_max_multi_dml_tables.sql test/test90_batch_limit_tests.sql test/test91_check_source_changes.sql test/test98_run_destroyer_functions.sql test/test99_cleanup.sql
