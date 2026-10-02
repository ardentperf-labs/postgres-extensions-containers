#!/bin/sh
set -eu
: "$PG_REGRESS"; : "$PGDATABASE"; : "$PG_MAJOR"; : "$TEST_OUTPUT"
case "$PG_MAJOR" in *[!0-9]*|'') echo "PG_MAJOR must be an integer" >&2; exit 77;; esac
extra=""
if [ "$PG_MAJOR" -ge 11 ]; then extra="$extra procedures"; fi
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="." --expecteddir="." --schedule="serial_schedule" --outputdir="$TEST_OUTPUT" --dbname="$PGDATABASE" $extra
