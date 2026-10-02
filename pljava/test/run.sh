#!/bin/sh
set -eu

examples_jar=/extensions/pljava/share/pljava/pljava-examples-1.6.10.jar

psql --set=ON_ERROR_STOP=1 \
  --command='CREATE EXTENSION pljava' \
  --command="SELECT sqlj.install_jar('file://${examples_jar}', 'upstream_examples', true)"

echo 'PASS: installed PL/Java and deployed the PGDG-packaged upstream examples'
