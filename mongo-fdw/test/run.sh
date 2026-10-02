#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

: "${MONGO_HOST:?MONGO_HOST must name the pre-seeded MongoDB fixture service}"
: "${MONGO_PORT:?MONGO_PORT must be set}"
: "${MONGO_USER_NAME:?MONGO_USER_NAME must be set}"
: "${MONGO_PWD?MONGO_PWD must be set (an empty value is allowed)}"
if [ "$PGDATABASE" != "contrib_regression" ]; then
    echo "Upstream mongo_fdw SQL explicitly reconnects to contrib_regression; set PGDATABASE=contrib_regression" >&2
    exit 64
fi
"$PG_REGRESS" --inputdir="." --expecteddir="." \
    --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" \
    --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" \
    --load-extension=mongo_fdw \
    server_options connection_validation dml select pushdown join_pushdown aggregate_pushdown limit_offset_pushdown
