\set ON_ERROR_STOP on
SET credcheck.password_min_length = 12;
DO $$ BEGIN
 BEGIN
  EXECUTE 'CREATE ROLE weak_password_probe LOGIN PASSWORD ''short''';
  RAISE EXCEPTION 'weak password accepted';
 EXCEPTION WHEN invalid_authorization_specification THEN
  IF position('credcheck.password_min_length' in SQLERRM) = 0 THEN RAISE; END IF;
 END;
END $$;
CREATE ROLE strong_password_probe LOGIN PASSWORD 'Safe-long-password-42!';
DROP ROLE strong_password_probe;
