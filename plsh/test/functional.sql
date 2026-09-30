\set ON_ERROR_STOP on
CREATE FUNCTION shell_probe(text) RETURNS text AS $sh$#!/bin/sh
printf '%s' "$1"
$sh$ LANGUAGE plsh;
DO $$ BEGIN IF shell_probe('shell-built-in') IS DISTINCT FROM 'shell-built-in' THEN RAISE EXCEPTION 'shell runtime failed'; END IF; END $$;
