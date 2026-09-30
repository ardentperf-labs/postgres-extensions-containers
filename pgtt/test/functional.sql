\set ON_ERROR_STOP on
CREATE GLOBAL TEMPORARY TABLE gtt_probe(id integer) ON COMMIT PRESERVE ROWS;
INSERT INTO gtt_probe VALUES (42);
DO $$ BEGIN IF (SELECT sum(id) FROM gtt_probe) IS DISTINCT FROM 42 THEN RAISE EXCEPTION 'global temporary table failed'; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pgtt_schema.pg_global_temp_tables WHERE relname='gtt_probe') THEN RAISE EXCEPTION 'GTT not registered'; END IF; END $$;
\connect app
DO $$ BEGIN IF EXISTS (SELECT FROM gtt_probe) THEN RAISE EXCEPTION 'session rows leaked'; END IF; END $$;
