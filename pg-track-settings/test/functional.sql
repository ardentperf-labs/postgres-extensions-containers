\set ON_ERROR_STOP on
SELECT pg_track_settings_snapshot();
DO $$ BEGIN
 IF NOT EXISTS (SELECT FROM pg_track_settings_list) THEN RAISE EXCEPTION 'snapshot empty'; END IF;
END $$;
SELECT pg_track_settings_reset();
