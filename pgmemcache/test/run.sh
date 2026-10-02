#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
if [ "${PGMEMCACHE_LOOPBACK_FIXTURE:-}" != ready ]; then
  echo 'Upstream suite requires memcached on the PostgreSQL server localhost:33211.' >&2
  exit 77
fi
exec "$PG_REGRESS" --inputdir=. --expecteddir=. --outputdir="$TEST_OUTPUT" --dbname=contrib_regression init test
