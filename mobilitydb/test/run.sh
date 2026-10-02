#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
echo 'Upstream CMake suite manages its own initdb/pg_ctl server; this CNPG connection runner cannot execute it faithfully.' >&2
exit 77
