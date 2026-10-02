#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=test --expecteddir=. --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  00_setup 01_basic 02_advisor 03_joinqual
