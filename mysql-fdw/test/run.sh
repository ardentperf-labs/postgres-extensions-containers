#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
if [ -z "${MYSQL_HOST:-}" ]; then
  echo 'Upstream suite requires a MySQL fixture reachable by runner and PostgreSQL; see mysql_init.sh.' >&2
  exit 77
fi
export MYSQL_PORT=${MYSQL_PORT:-3306} MYSQL_USER_NAME=${MYSQL_USER_NAME:-edb} MYSQL_PASS=${MYSQL_PASS:-edb} MYSQL_PWD=${MYSQL_PWD:-edb}
sh ./mysql_init.sh
exec "$PG_REGRESS" --inputdir=. --expecteddir=. --outputdir="$TEST_OUTPUT" --dbname=contrib_regression server_options connection_validation dml select pushdown join_pushdown aggregate_pushdown limit_offset_pushdown misc
