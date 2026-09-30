DO $$
DECLARE
    result pg_background_run_result;
BEGIN
    result := pg_background_run('SELECT 42');
    IF result.completed IS DISTINCT FROM true OR result.has_error IS DISTINCT FROM false THEN
        RAISE EXCEPTION 'background query did not complete cleanly: %', result;
    END IF;
    IF result.row_count <> 1 OR result.command_tag <> 'SELECT' THEN
        RAISE EXCEPTION 'unexpected background query result metadata: %', result;
    END IF;
END
$$;
