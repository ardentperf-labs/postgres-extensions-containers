#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=. --expecteddir=compat_18 --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  select activity privileges cleanup
