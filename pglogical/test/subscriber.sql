\set ON_ERROR_STOP on
\getenv host PGHOST
\getenv port PGPORT
\getenv provider_database PGDATABASE
\getenv sslmode PGSSLMODE
CREATE TABLE public.replication_fixture(id integer PRIMARY KEY, value text NOT NULL);
SELECT pglogical.create_node('subscriber', format('host=%s port=%s dbname=pglogical_subscriber user=pglogical_fixture password=Pglogical-fixture-2026! sslmode=%s', :'host', :'port', :'sslmode'));
SELECT pglogical.create_subscription(
 subscription_name := 'fixture',
 provider_dsn := format('host=%s port=%s dbname=%s user=pglogical_fixture password=Pglogical-fixture-2026! sslmode=%s', :'host', :'port', :'provider_database', :'sslmode'),
 replication_sets := ARRAY['default'],
 synchronize_structure := false,
 synchronize_data := true);
