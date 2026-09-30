\set ON_ERROR_STOP on
CREATE EXTENSION hstore;
CREATE EXTENSION ltree;
CREATE EXTENSION hstore_plpython3u;
CREATE EXTENSION jsonb_plpython3u;
CREATE EXTENSION ltree_plpython3u;
CREATE FUNCTION python_runtime() RETURNS jsonb TRANSFORM FOR TYPE jsonb LANGUAGE plpython3u AS $$
import gzip
import hashlib
import sqlite3
import ssl
connection = sqlite3.connect(':memory:')
answer = connection.execute('SELECT 42').fetchone()[0]
connection.close()
valid = gzip.decompress(gzip.compress(b'abc')) == b'abc'
valid = valid and hashlib.sha256(b'abc').hexdigest() == 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
valid = valid and bool(ssl.OPENSSL_VERSION)
return {'answer': answer, 'valid': valid}
$$;
CREATE FUNCTION python_hstore() RETURNS hstore TRANSFORM FOR TYPE hstore LANGUAGE plpython3u AS $$
return {'answer': '42'}
$$;
CREATE FUNCTION python_ltree(ltree) RETURNS text TRANSFORM FOR TYPE ltree LANGUAGE plpython3u AS $$
return '.'.join(args[0])
$$;
CREATE FUNCTION python_spi() RETURNS integer LANGUAGE plpython3u AS $$
return plpy.execute('SELECT 42 AS answer')[0]['answer']
$$;
DO $$ BEGIN
 IF python_runtime() IS DISTINCT FROM '{"answer":42,"valid":true}'::jsonb
 OR (python_hstore()->'answer') IS DISTINCT FROM '42'
 OR python_ltree('Top.Science'::ltree) IS DISTINCT FROM 'Top.Science'
 OR python_spi() IS DISTINCT FROM 42 THEN
  RAISE EXCEPTION 'Python runtime, SPI or packaged transform result mismatch';
 END IF;
END $$;
