\set ON_ERROR_STOP on
CREATE TABLE fincore_probe AS SELECT generate_series(1,1000) id;
DO $$ BEGIN
 IF NOT EXISTS (SELECT FROM pgfincore('fincore_probe')) THEN RAISE EXCEPTION 'relation cache inspection empty'; END IF;
END $$;
