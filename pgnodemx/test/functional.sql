\set ON_ERROR_STOP on
DO $$ BEGIN
 IF NOT EXISTS (SELECT FROM proc_meminfo()) THEN RAISE EXCEPTION 'proc memory metrics empty'; END IF;
 IF NOT EXISTS (SELECT FROM proc_pid_stat()) THEN RAISE EXCEPTION 'backend metrics empty'; END IF;
END $$;
