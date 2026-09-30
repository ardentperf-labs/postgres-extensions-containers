DO $$
DECLARE
    snapshot_at timestamptz;
BEGIN
    snapshot_at := pgstatviz.snapshot();
    IF snapshot_at IS NULL OR NOT EXISTS (SELECT FROM pgstatviz.snapshots WHERE snapshot_tstamp = snapshot_at) THEN
        RAISE EXCEPTION 'pg_statviz did not persist the snapshot in its database table';
    END IF;
    PERFORM pgstatviz.delete_snapshots();
    IF EXISTS (SELECT FROM pgstatviz.snapshots) THEN
        RAISE EXCEPTION 'pg_statviz.delete_snapshots did not remove snapshot rows';
    END IF;
END
$$;
