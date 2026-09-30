\set ON_ERROR_STOP on
DO $$ DECLARE result text; BEGIN
 SELECT csv_agg(t) INTO result FROM (VALUES (1,'a,b')) AS t(id,label);
 IF result IS NULL OR position('"a,b"' in result) = 0 THEN RAISE EXCEPTION 'CSV quoting failed: %',result; END IF;
END $$;
