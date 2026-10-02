#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec psql -X -v ON_ERROR_STOP=1 -f debian/tests/script.sql
