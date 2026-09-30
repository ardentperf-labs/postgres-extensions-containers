DO $$
DECLARE
    samples bigint;
BEGIN
    PERFORM pg_sleep(0.25);
    SELECT count(*) INTO samples
    FROM pg_wait_sampling_profile
    WHERE event_type IS NOT NULL AND count > 0;
    IF samples = 0 THEN
        RAISE EXCEPTION 'wait sampler did not record any wait events';
    END IF;
END
$$;
