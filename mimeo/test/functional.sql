
INSERT INTO public.dblink_mapping_mimeo (data_source, username, pwd)
VALUES (
    format('host=%s port=%s dbname=mimeo_source sslmode=require', :'source_host', :'source_port'),
    'postgres',
    :'source_password'
)
RETURNING data_source_id \gset
SELECT public.table_maker(
    'public.mimeo_source',
    :data_source_id,
    'public.mimeo_copy',
    p_pulldata := true,
    p_jobmon := false
);
SELECT count(*) FROM public.mimeo_copy;
