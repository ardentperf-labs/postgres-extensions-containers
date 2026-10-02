#!/bin/sh
set -eu
: "${PG_REGRESS:?PG_REGRESS must name the native pg_regress binary}"
: "${TEST_OUTPUT:?TEST_OUTPUT must name a writable output directory}"
mkdir -p "$TEST_OUTPUT"
cd upstream
# Keep the upstream test config intact in test/upstream. Rewrite only its
# relative HBA path and append the mounted package paths needed by the private
# pg_regress server; the package remains mounted, never installed into $libdir.
hba_file="$PWD/regress-pg_hba.conf"
temp_config="$TEST_OUTPUT/pglogical-temp.conf"
sed "s#^hba_file = './regress-pg_hba.conf'#hba_file = '$hba_file'#" regress-postgresql.conf > "$temp_config"
cat >> "$temp_config" <<'CONFIG'
extension_control_path = '$system:/extensions/pglogical/share'
dynamic_library_path = '$libdir:/extensions/pglogical/lib'
output_plugin_libraries = 'pgoutput,test_decoding,pglogical_output'
CONFIG
# Ignore the shared CNPG connection environment: upstream's Makefile starts an
# isolated local server using this config and its own regression database.
unset PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE PGSSLMODE PGSSLROOTCERT
# Match upstream pglogical Makefile's regresscheck invocation and full order.
exec "$PG_REGRESS" --inputdir="." --expecteddir="." --temp-config="$temp_config" --temp-instance="$TEST_OUTPUT/pglogical-temp-instance" --outputdir="$TEST_OUTPUT" --dbname=regression --create-role=logical preseed infofuncs init_fail init preseed_check basic extended conflict_secondary_unique toasted replication_set add_table matview bidirectional primary_key interfaces foreign_key functions copy sequence triggers parallel row_filter row_filter_sampling att_list column_filter apply_delay multiple_upstreams node_origin_cascade drop
