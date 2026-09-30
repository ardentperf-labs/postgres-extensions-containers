\set ON_ERROR_STOP on
\getenv proxy_host PGHOST
\getenv proxy_database PGDATABASE
\getenv proxy_sslmode PGSSLMODE
-- Public credentials used only inside this disposable fixture cluster.
CREATE ROLE plproxy_fixture LOGIN PASSWORD 'Plproxy-fixture-2026!';
SELECT format('CREATE FUNCTION proxy_probe() RETURNS integer AS %L LANGUAGE plproxy',
  format('CONNECT %L; SELECT 42;',
    format('host=%s dbname=%s user=plproxy_fixture password=Plproxy-fixture-2026! sslmode=%s', :'proxy_host', :'proxy_database', :'proxy_sslmode'))) \gexec
DO $$ BEGIN IF proxy_probe() IS DISTINCT FROM 42 THEN RAISE EXCEPTION 'proxy query failed'; END IF; END $$;
DROP FUNCTION proxy_probe();
DROP ROLE plproxy_fixture;
