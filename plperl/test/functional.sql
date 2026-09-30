\set ON_ERROR_STOP on
CREATE EXTENSION plperlu;
CREATE EXTENSION hstore;
CREATE EXTENSION bool_plperl;
CREATE EXTENSION bool_plperlu;
CREATE EXTENSION hstore_plperl;
CREATE EXTENSION hstore_plperlu;
CREATE EXTENSION jsonb_plperl;
CREATE EXTENSION jsonb_plperlu;
CREATE FUNCTION perl_upper(text) RETURNS text LANGUAGE plperl AS $$return uc($_[0]);$$;
CREATE FUNCTION perl_json() RETURNS jsonb TRANSFORM FOR TYPE jsonb LANGUAGE plperl AS $$return { answer => 42 };$$;
CREATE FUNCTION perl_hstore() RETURNS hstore TRANSFORM FOR TYPE hstore LANGUAGE plperl AS $$return { answer => '42' };$$;
CREATE FUNCTION perl_bool(boolean) RETURNS boolean TRANSFORM FOR TYPE bool LANGUAGE plperl AS $$return $_[0];$$;
CREATE FUNCTION perlu_json() RETURNS jsonb TRANSFORM FOR TYPE jsonb LANGUAGE plperlu AS $$return { answer => 42 };$$;
CREATE FUNCTION perlu_hstore() RETURNS hstore TRANSFORM FOR TYPE hstore LANGUAGE plperlu AS $$return { answer => '42' };$$;
CREATE FUNCTION perlu_bool(boolean) RETURNS boolean TRANSFORM FOR TYPE bool LANGUAGE plperlu AS $$return $_[0];$$;
CREATE FUNCTION perlu_driver() RETURNS integer LANGUAGE plperlu AS $$
 use DBI;
 use DBD::Pg;
 my $driver = DBI->install_driver('Pg');
 return $driver->{Name} eq 'Pg' ? 42 : 0;
$$;
DO $$ BEGIN
 IF perl_upper('hello') IS DISTINCT FROM 'HELLO'
 OR perl_json() IS DISTINCT FROM '{"answer":42}'::jsonb
 OR perlu_json() IS DISTINCT FROM '{"answer":42}'::jsonb
 OR (perl_hstore()->'answer') IS DISTINCT FROM '42'
 OR (perlu_hstore()->'answer') IS DISTINCT FROM '42'
 OR perl_bool(false) IS DISTINCT FROM false
 OR perl_bool(true) IS DISTINCT FROM true
 OR perlu_bool(false) IS DISTINCT FROM false
 OR perlu_bool(true) IS DISTINCT FROM true THEN
  RAISE EXCEPTION 'Perl language or transform result mismatch';
 END IF;
END $$;
SELECT perlu_driver() = 42 AS passed \gset
\if :passed
\else
 \quit 1
\endif
