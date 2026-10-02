#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$TEST_OUTPUT"
mkdir -p "$TEST_OUTPUT/ogr-input/sql" "$TEST_OUTPUT/ogr-input/expected"
cd upstream
srcdir=$(pwd)
for name in file pgsql import; do
  perl -pe "s#\\@abs_srcdir\\@#$srcdir#g" "input/$name.source" > "$TEST_OUTPUT/ogr-input/sql/$name.sql"
  perl -pe "s#\\@abs_srcdir\\@#$srcdir#g" "output/$name.source" > "$TEST_OUTPUT/ogr-input/expected/$name.out"
done
exec "$PG_REGRESS" --encoding=UTF8 --inputdir="$TEST_OUTPUT/ogr-input" --expecteddir="$TEST_OUTPUT/ogr-input" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" file pgsql import
