#!/bin/sh
set -eu
: "$PG_TEST_PERL"
: "$TEST_OUTPUT"
command -v prove >/dev/null 2>&1 || { echo "Native TAP lane requires Perl prove" >&2; exit 77; }
mkdir -p "$TEST_OUTPUT"
exec prove -I "$PG_TEST_PERL" -I upstream/t -v upstream/t/*.pl
