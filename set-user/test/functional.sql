\set ON_ERROR_STOP on
CREATE ROLE switched_probe;
SELECT set_user('switched_probe');
DO $$ BEGIN IF current_user IS DISTINCT FROM 'switched_probe' THEN RAISE EXCEPTION 'role did not switch'; END IF; END $$;
SELECT reset_user();
DROP ROLE switched_probe;
