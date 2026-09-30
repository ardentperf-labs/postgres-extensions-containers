\set ON_ERROR_STOP on
CREATE TABLE dirty_probe(id integer) WITH (autovacuum_enabled=false);
INSERT INTO dirty_probe VALUES(42);
DELETE FROM dirty_probe;
DO $$ BEGIN
 IF (SELECT count(*) FROM pg_dirtyread('dirty_probe') AS t(id integer) WHERE id=42) IS DISTINCT FROM 1 THEN RAISE EXCEPTION 'dead tuple not recovered'; END IF;
 IF EXISTS (SELECT FROM dirty_probe) THEN RAISE EXCEPTION 'normal scan exposed deleted row'; END IF;
END $$;
