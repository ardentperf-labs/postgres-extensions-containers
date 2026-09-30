\set ON_ERROR_STOP on
\getenv target_uri APP_URI
SET ROLE app;
CREATE EXTENSION dblink;
SELECT result = 42 AS passed FROM dblink(replace(:'target_uri', '/*', '/'), 'SELECT 42') AS remote_result(result integer) \gset
\if :passed
\else
  \quit 1
\endif
DO $$ BEGIN
 BEGIN
  EXECUTE 'CREATE EXTENSION file_fdw';
  RAISE EXCEPTION 'non-allowlisted privileged extension accepted';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END $$;
