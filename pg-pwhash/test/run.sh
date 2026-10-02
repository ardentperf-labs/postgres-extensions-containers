#!/bin/sh
set -eu
: "${PG_REGRESS:=pg_regress}"
: "${TEST_OUTPUT:=$PWD/results}"
mkdir -p "$TEST_OUTPUT"
cd upstream
exec "$PG_REGRESS" --inputdir="." --expecteddir="." --dbname="${PGDATABASE:-regression}" --outputdir="$TEST_OUTPUT" pg_pwhash argon2 argon2_openssl scrypt scrypt_crypt scrypt_libscrypt yescrypt
