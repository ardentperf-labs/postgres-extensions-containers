#!/bin/sh
set -eu
echo "Bucardo upstream package tests require root to stop system PostgreSQL, create a local trust-auth cluster, and run the Bucardo daemon; they cannot run against the remote CNPG scratch server." >&2
exit 77
