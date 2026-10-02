#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT" "$TEST_OUTPUT/regress" "$TEST_OUTPUT/isolation"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

: "${PG_ISOLATION_REGRESS:?PG_ISOLATION_REGRESS must be set to pg_isolation_regress}"
regress_dir="pg_documentdb/src/test/regress"
schedule="$TEST_OUTPUT/basic_schedule_$PG_MAJOR"
cp "$regress_dir/basic_schedule" "$schedule"
(cd "$regress_dir" && bash mutate_schedule.sh "$schedule" "$PG_MAJOR")
export PGISOLATIONTIMEOUT=60
export PG_REGRESS_DIFF_OPTS=-dU10
extensions='--load-extension=tsm_system_rows --load-extension=pg_cron --load-extension=vector --load-extension=postgis --load-extension=documentdb_core --load-extension=documentdb'
# The extension list above is deliberately the exact list in the upstream native test Makefile.
# shellcheck disable=SC2086
"$PG_REGRESS" --inputdir="$regress_dir" --expecteddir="$regress_dir" \
    --outputdir="$TEST_OUTPUT/regress" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" \
    --encoding=UTF8 $extensions --schedule="$schedule"
"$PG_ISOLATION_REGRESS" --inputdir="$regress_dir" --expecteddir="$regress_dir" \
    --outputdir="$TEST_OUTPUT/isolation" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" \
    --encoding=UTF8 $extensions --schedule="$regress_dir/isolation_schedule"
