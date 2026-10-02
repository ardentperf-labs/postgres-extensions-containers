#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
tests_dir="$script_dir/upstream/tests"

export EXE_DIR="$tests_dir"
export TEST_INPUT_DIR="$tests_dir"
export TEST_OUTPUT_DIR="$TEST_OUTPUT"
TEST_PGUSER=default_perm_user
export TEST_PGUSER
export TEST_ROLE_SUPERUSER=super_user
export TEST_ROLE_DEFAULT_PERM_USER=default_perm_user
export TEST_ROLE_DEFAULT_PERM_USER_2=default_perm_user_2
export TEST_DBNAME=single
export USER=postgres
export TEST_TABLESPACE1_PATH="$TEST_OUTPUT/tablespace1"
export TEST_TABLESPACE2_PATH="$TEST_OUTPUT/tablespace2"
mkdir -p "$TEST_TABLESPACE1_PATH" "$TEST_TABLESPACE2_PATH"
cd "$tests_dir"
exec ./pg_regress.sh \
    --host=127.0.0.1 \
    --load-extension=plpgsql \
    --create-role=super_user,default_perm_user,default_perm_user_2 \
    --dbname=single \
    --launcher="$tests_dir/runner.sh" \
    --inputdir="$tests_dir" \
    --outputdir="$TEST_OUTPUT" \
    --port="$PGPORT"
