#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

"$PG_REGRESS" --inputdir="test" --expecteddir="test" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" --load-extension=credcheck 01_username 02_password 03_rename 04_alter_pwd 05_reuse_history 06_reuse_interval 07_valid_until 08_first_login 09_plpgsql
