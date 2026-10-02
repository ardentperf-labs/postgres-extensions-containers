#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
trap 'cp -R results "$TEST_OUTPUT/" 2>/dev/null || true' EXIT
make PG_CONFIG="/usr/lib/postgresql/$PG_MAJOR/bin/pg_config" test
