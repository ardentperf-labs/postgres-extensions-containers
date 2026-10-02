#!/bin/sh
set -eu

mkdir -p "$TEST_OUTPUT"
script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$script_dir/upstream"

"$PG_REGRESS" --inputdir="." --expecteddir="." --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" --host="$PGHOST" --port="$PGPORT" --user="$PGUSER" security rum rum_validate rum_hash ruminv timestamp orderby orderby_hash altorder altorder_hash limits int2 int4 int8 float4 float8 money oid time timetz date interval macaddr inet cidr text varchar char bytea bit varbit numeric rum_weight expr array

mkdir -p "$TEST_OUTPUT/isolation"
"$PG_ISOLATION_REGRESS" \
    --inputdir=. \
    --expecteddir=. \
    --outputdir="$TEST_OUTPUT/isolation" \
    --dbname="$PGDATABASE" \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --user="$PGUSER" \
    --load-extension=rum \
    predicate-rum predicate-rum-2
