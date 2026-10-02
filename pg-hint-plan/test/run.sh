#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=. --expecteddir=. --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression --encoding=UTF8 \
  init base_plan pg_hint_plan ut-init ut-A ut-S ut-J ut-L ut-G ut-R ut-fdw ut-W ut-T ut-fini plpgsql hint_table disable_index oldextversions
