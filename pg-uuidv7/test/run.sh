#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=test --expecteddir=test --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  001_setup 002_uuid_generate_v7 003_uuid_v7_to_timestamptz 004_uuid_timestamptz_to_v7 005_uuid_v7_to_timestamp 006_uuid_timestamp_to_v7
