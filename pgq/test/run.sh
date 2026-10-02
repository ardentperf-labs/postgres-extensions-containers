#!/bin/sh
set -eu
: "${PG_REGRESS:=pg_regress}"
: "${TEST_OUTPUT:=$PWD/results}"
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="." --expecteddir="." --dbname="${PGDATABASE:-regression}" --outputdir="$TEST_OUTPUT" pgq_init_ext pgq_core pgq_core_disabled pgq_core_tx_limit pgq_session_role pgq_perms trigger_base trigger_sess_role trigger_types trigger_trunc trigger_ignore trigger_pkey trigger_deny trigger_when trigger_extra_args trigger_extra_cols trigger_backup clean_ext pgq_init_ext switch_plonly pgq_core pgq_core_disabled pgq_session_role pgq_perms trigger_base trigger_sess_role trigger_types trigger_trunc trigger_ignore trigger_pkey trigger_deny trigger_when trigger_extra_args trigger_extra_cols trigger_backup
