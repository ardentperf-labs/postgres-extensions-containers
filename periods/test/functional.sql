\set ON_ERROR_STOP on
CREATE TABLE period_probe (id int, starts date, ends date);
SELECT periods.add_period('period_probe', 'validity', 'starts', 'ends');
INSERT INTO period_probe VALUES (1, '2026-01-01', '2026-02-01');
DO $$ BEGIN
 BEGIN
  INSERT INTO period_probe VALUES (2, '2026-02-01', '2026-01-01');
  RAISE EXCEPTION 'inverted period accepted';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
END $$;
