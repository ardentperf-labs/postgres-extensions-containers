#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
export PYTHONPATH="$PWD/python-plprofiler${PYTHONPATH:+:$PYTHONPATH}"
export PATH="$PWD/../bin:$PATH"
# The package test uses pg_virtualenv only to provide a server. Execute its
# unchanged heredoc body against the disposable mounted-image CNPG server.
sed -n '/^  set -eux$/,/^EOF$/p' debian/tests/plprofiler | sed '$d' | sh
