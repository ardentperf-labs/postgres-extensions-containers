\set ON_ERROR_STOP on
DO $$ DECLARE before_priority integer; BEGIN
 before_priority := get_backend_priority(pg_backend_pid());
 IF NOT set_backend_priority(pg_backend_pid(), least(19,before_priority+1)) THEN RAISE EXCEPTION 'priority update failed'; END IF;
 IF get_backend_priority(pg_backend_pid()) IS DISTINCT FROM least(19,before_priority+1) THEN RAISE EXCEPTION 'priority unchanged'; END IF;
END $$;
