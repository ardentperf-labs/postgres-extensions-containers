#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=test --expecteddir=. --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  hypopg hypo_brin hypo_index_part hypo_include hypo_hash hypo_hide_index
