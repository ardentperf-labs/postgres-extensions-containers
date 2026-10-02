#!/bin/sh
set -eu
: "${PGUSER:=postgres}"
: "${PGDATABASE:=postgres}"
export PGUSER PGDATABASE
mkdir -p /tmp/testts /tmp/1testts '/tmp/test ts' '/tmp/test"ts'
psql --set=ON_ERROR_STOP=1 --dbname=postgres -c "CREATE TABLESPACE testts LOCATION '/tmp/testts'"
psql --set=ON_ERROR_STOP=1 --dbname=postgres -c "CREATE TABLESPACE \"1testts\" LOCATION '/tmp/1testts'"
psql --set=ON_ERROR_STOP=1 --dbname=postgres -c "CREATE TABLESPACE \"test ts\" LOCATION '/tmp/test ts'"
psql --set=ON_ERROR_STOP=1 --dbname=postgres -c "CREATE TABLESPACE \"test\"\"ts\" LOCATION '/tmp/test\"ts'"
