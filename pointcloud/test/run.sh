#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="pgsql" --expecteddir="pgsql" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" pointcloud pointcloud_columns schema
