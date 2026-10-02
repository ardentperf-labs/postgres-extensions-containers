#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=. --expecteddir=. --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  squeeze
