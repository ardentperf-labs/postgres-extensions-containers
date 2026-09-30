DROP TABLE IF EXISTS public.pg_repack_fixture;
CREATE TABLE public.pg_repack_fixture (id integer PRIMARY KEY, payload text NOT NULL);
INSERT INTO public.pg_repack_fixture
SELECT g, repeat('x', 2048) FROM generate_series(1, 3000) AS g;
UPDATE public.pg_repack_fixture SET payload = repeat('y', 2048);
