\set ON_ERROR_STOP on
CREATE TABLE facets_probe(id bigint PRIMARY KEY, category text);
INSERT INTO facets_probe VALUES (1,'red'),(2,'red'),(3,'blue');
SELECT faceting.add_faceting_to_table('facets_probe', key=>'id', facets=>ARRAY[faceting.plain_facet('category')]);
DO $$ BEGIN
 IF (SELECT sum(cardinality) FROM faceting.top_values('facets_probe'::regclass, n=>10)) IS DISTINCT FROM 3 THEN RAISE EXCEPTION 'facet count mismatch'; END IF;
END $$;
