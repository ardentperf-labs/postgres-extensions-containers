\set ON_ERROR_STOP on
\getenv host PGHOST
\getenv port PGPORT
\getenv provider_database PGDATABASE
\getenv sslmode PGSSLMODE
-- PGDG ships this empty compatibility extension for upgrades from PostgreSQL 9.4.
CREATE EXTENSION pglogical_origin;
-- Public credentials exclusively for this disposable test cluster.
CREATE ROLE pglogical_fixture LOGIN SUPERUSER REPLICATION PASSWORD 'Pglogical-fixture-2026!';
CREATE TABLE public.replication_fixture(id integer PRIMARY KEY, value text NOT NULL);
INSERT INTO public.replication_fixture VALUES (1, 'initial-copy');
SELECT pglogical.create_node('provider', format('host=%s port=%s dbname=%s user=pglogical_fixture password=Pglogical-fixture-2026! sslmode=%s', :'host', :'port', :'provider_database', :'sslmode'));
SELECT pglogical.replication_set_add_table('default', 'public.replication_fixture');
