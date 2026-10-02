#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
"$PG_REGRESS" --inputdir=h3/test --expecteddir=h3/test --outputdir="$TEST_OUTPUT/h3" --dbname=contrib_regression --load-extension=h3 clustering deprecated edge extension hierarchy indexing inspection miscellaneous opclass_brin opclass_btree opclass_hash opclass_spgist regions traversal type vertex
exec "$PG_REGRESS" --inputdir=h3_postgis/test --expecteddir=h3_postgis/test --outputdir="$TEST_OUTPUT/h3_postgis" --dbname=contrib_regression --load-extension=h3 --load-extension=postgis --load-extension=postgis_raster --load-extension=h3_postgis deprecations postgis rasters
