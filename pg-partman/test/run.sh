#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
psql -X -v ON_ERROR_STOP=1 <<'SQL'
CREATE SCHEMA partman;
CREATE EXTENSION pg_partman SCHEMA partman;
CREATE EXTENSION pgtap SCHEMA public;
SQL
exec pg_prove -ovf test/*.sql
