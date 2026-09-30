\set ON_ERROR_STOP on
SELECT plan(2);
SELECT is(2+2,4,'arithmetic fixture');
SELECT ok(true,'boolean assertion');
DO $$ BEGIN
 IF EXISTS (SELECT FROM finish() AS result WHERE result LIKE 'not ok%') THEN RAISE EXCEPTION 'TAP assertions failed'; END IF;
END $$;
