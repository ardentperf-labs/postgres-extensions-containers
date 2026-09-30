\set ON_ERROR_STOP on
CREATE TABLE rewrite_probe(id integer PRIMARY KEY, value text);
INSERT INTO rewrite_probe VALUES (1,'preserved');
CREATE TABLE rewrite_new(id bigint PRIMARY KEY, value text);
SELECT rewrite_table('rewrite_probe','rewrite_new','rewrite_old');
DO $$ BEGIN
 IF (SELECT value FROM rewrite_probe WHERE id=1) IS DISTINCT FROM 'preserved' THEN RAISE EXCEPTION 'rewritten data mismatch'; END IF;
 IF (SELECT atttypid FROM pg_attribute WHERE attrelid='rewrite_probe'::regclass AND attname='id') IS DISTINCT FROM 'bigint'::regtype THEN RAISE EXCEPTION 'table was not rewritten'; END IF;
END $$;
DROP TABLE rewrite_old;
