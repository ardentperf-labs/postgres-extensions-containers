\set ON_ERROR_STOP on
DO $$ BEGIN
 IF lev('kitten','kitten') IS DISTINCT FROM 1 THEN RAISE EXCEPTION 'identity similarity failed'; END IF;
 IF lev('kitten','sitting') IS NULL OR lev('kitten','sitting') >= 1 THEN RAISE EXCEPTION 'different strings matched exactly'; END IF;
END $$;
