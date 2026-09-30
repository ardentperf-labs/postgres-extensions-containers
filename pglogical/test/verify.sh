#!/bin/sh
set -eu
psql -X -v ON_ERROR_STOP=1 -f /sql/functional.sql
psql -X -v ON_ERROR_STOP=1 -d pglogical_subscriber -f /sql/subscriber.sql
wait_for_rows() {
  expected=$1
  for attempt in $(seq 1 120); do
    result=$(psql -X -v ON_ERROR_STOP=1 -At -d pglogical_subscriber -c "SELECT coalesce(string_agg(id::text || ':' || value, ',' ORDER BY id), '') FROM public.replication_fixture")
    if [ "$result" = "$expected" ]; then return 0; fi
    sleep 1
  done
  printf 'Subscriber did not reach expected state: %s; actual: %s\n' "$expected" "$result" >&2
  exit 1
}
wait_for_rows '1:initial-copy'
psql -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.replication_fixture VALUES (2,'inserted'); UPDATE public.replication_fixture SET value='updated' WHERE id=1;"
wait_for_rows '1:updated,2:inserted'
psql -X -v ON_ERROR_STOP=1 -c 'DELETE FROM public.replication_fixture WHERE id=1;'
wait_for_rows '2:inserted'
psql -X -v ON_ERROR_STOP=1 -c 'TRUNCATE public.replication_fixture;'
wait_for_rows ''
psql -X -v ON_ERROR_STOP=1 -d pglogical_subscriber -c "SELECT pglogical.drop_subscription('fixture'); SELECT pglogical.drop_node('subscriber');"
psql -X -v ON_ERROR_STOP=1 -c "SELECT pglogical.drop_node('provider'); DROP ROLE pglogical_fixture;"
printf 'Initial copy and INSERT/UPDATE/DELETE/TRUNCATE replication passed\n'
