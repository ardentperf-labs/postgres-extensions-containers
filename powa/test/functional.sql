
SELECT sum(probe_value)
FROM generate_series(1, 200) AS cnpg_powa_probe(probe_value);
SELECT powa_take_snapshot();
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM powa_statements_history_current AS history
        JOIN powa_statements AS statement
          USING (srvid, queryid, dbid, userid)
        WHERE history.srvid = 0
          AND statement.dbid = (
              SELECT oid FROM pg_database WHERE datname = current_database()
          )
          AND statement.query LIKE '%cnpg_powa_probe%'
          AND (history.record).calls > 0
          AND (history.record).rows = 1
    ) THEN
        RAISE EXCEPTION 'PoWA did not persist the functional query in the current snapshot';
    END IF;
END
$$;
