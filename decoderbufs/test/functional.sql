\set ON_ERROR_STOP on
CREATE TABLE public.decoderbufs_fixture(id integer PRIMARY KEY, value text NOT NULL);
ALTER TABLE public.decoderbufs_fixture REPLICA IDENTITY FULL;
SELECT slot_name FROM pg_create_logical_replication_slot('decoderbufs_fixture', 'decoderbufs');
INSERT INTO public.decoderbufs_fixture VALUES (1, 'decoderbufs-insert-probe');
UPDATE public.decoderbufs_fixture SET value = 'decoderbufs-update-probe' WHERE id = 1;
DELETE FROM public.decoderbufs_fixture WHERE id = 1;
CREATE TEMP TABLE decoded_debug AS
 SELECT data FROM pg_logical_slot_peek_changes('decoderbufs_fixture', NULL, NULL, 'debug-mode', '1');
DO $$ BEGIN
 IF NOT EXISTS (SELECT FROM decoded_debug WHERE data LIKE '%table[public.decoderbufs_fixture], op[0]%' AND data LIKE '%datum[decoderbufs-insert-probe]%')
 OR NOT EXISTS (SELECT FROM decoded_debug WHERE data LIKE '%table[public.decoderbufs_fixture], op[1]%' AND data LIKE '%datum[decoderbufs-update-probe]%')
 OR NOT EXISTS (SELECT FROM decoded_debug WHERE data LIKE '%table[public.decoderbufs_fixture], op[2]%' AND data LIKE '%datum[decoderbufs-update-probe]%') THEN
  RAISE EXCEPTION 'decoderbufs did not decode INSERT/UPDATE/DELETE with their values';
 END IF;
END $$;
CREATE TEMP TABLE decoded_binary AS
 SELECT data FROM pg_logical_slot_get_binary_changes('decoderbufs_fixture', NULL, NULL);
DO $$ BEGIN
 IF (SELECT count(*) FROM decoded_binary) < 9
 OR NOT EXISTS (SELECT FROM decoded_binary WHERE position(convert_to('decoderbufs-insert-probe', 'UTF8') in data) > 0)
 OR NOT EXISTS (SELECT FROM decoded_binary WHERE position(convert_to('decoderbufs-update-probe', 'UTF8') in data) > 0) THEN
  RAISE EXCEPTION 'decoderbufs binary protobuf messages lack transaction records or values';
 END IF;
END $$;
SELECT pg_drop_replication_slot('decoderbufs_fixture');
DROP TABLE public.decoderbufs_fixture;
