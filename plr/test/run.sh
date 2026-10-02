#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=. --expecteddir=. --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  plr bad_fun opt_window do out_args plr_transaction opt_window_frame parallel
