#!/bin/sh
set -eu

psql --set=ON_ERROR_STOP=1 --command='CREATE ROLE dba SUPERUSER NOINHERIT'
psql --set=ON_ERROR_STOP=1 --command='GRANT dba TO postgres'
psql --set=ON_ERROR_STOP=1 --command='CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; CREATE EXTENSION IF NOT EXISTS pgcrypto; CREATE EXTENSION IF NOT EXISTS pgtap;'
psql --set=ON_ERROR_STOP=1 --command='SET ROLE dba; CREATE EXTENSION IF NOT EXISTS "pg-gvm";'
psql --set=ON_ERROR_STOP=1 --file=upstream/gvmd-tables.sql

exec pg_prove -d "${PGDATABASE:?PGDATABASE is required}" upstream/tests/*.sql
