\set ON_ERROR_STOP on
CREATE TABLE permissions_probe(id integer);
GRANT SELECT ON permissions_probe TO app;
DO $$ BEGIN
 IF NOT EXISTS (SELECT FROM table_permissions WHERE object_name='permissions_probe' AND role_name='app' AND permission='SELECT' AND granted) THEN RAISE EXCEPTION 'grant not visible'; END IF;
END $$;
