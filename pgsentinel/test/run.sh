#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=src --expecteddir=src --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  pgsentinel-test
