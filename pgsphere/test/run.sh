#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=. --expecteddir=. --outputdir="$TEST_OUTPUT" \
  --dbname=contrib_regression  \
  init version tables points euler circle line ellipse poly path box index contains_ops contains_ops_compat bounding_box_gist gnomo epochprop contains overlaps spoint_brin sbox_brin selectivity knn output_precision healpix moc moc1 moc100 mocautocast gist_support moc_options
