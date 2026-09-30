
DO $$
DECLARE created record;
BEGIN
    PERFORM pgq.create_queue('cnpg_londiste_functional');
    PERFORM * FROM pgq_node.register_location(
        'cnpg_londiste_functional', 'cnpg_root', 'dbname=app', false
    );
    SELECT * INTO created FROM pgq_node.create_node(
    i_queue_name := 'cnpg_londiste_functional',
    i_node_type := 'root',
    i_node_name := 'cnpg_root',
    i_worker_name := 'cnpg_worker',
    i_provider_name := NULL,
    i_global_watermark := NULL,
    i_combined_queue := NULL
    );
    IF created.ret_code IS DISTINCT FROM 200 THEN
        RAISE EXCEPTION 'pgq_node could not create a root node: %', created;
    END IF;
END
$$;
CREATE TABLE public.londiste_fixture (id integer PRIMARY KEY, value text NOT NULL);
DO $$
DECLARE registered record;
BEGIN
    SELECT * INTO registered FROM londiste.local_add_table(
        'cnpg_londiste_functional',
        'public.londiste_fixture',
        ARRAY[]::text[],
        '',
        'public.londiste_fixture'
    );
    IF registered.ret_code IS DISTINCT FROM 200 THEN
        RAISE EXCEPTION 'Londiste could not register a table: %', registered;
    END IF;
    IF NOT EXISTS (
        SELECT FROM londiste.get_table_list('cnpg_londiste_functional')
        WHERE table_name = 'public.londiste_fixture'
    ) THEN
        RAISE EXCEPTION 'Londiste table metadata did not list the registered table';
    END IF;
END
$$;
INSERT INTO public.londiste_fixture VALUES (1, 'inserted');
UPDATE public.londiste_fixture SET value = 'updated' WHERE id = 1;
DELETE FROM public.londiste_fixture WHERE id = 1;
DO $$
DECLARE
    v_queue_id integer;
    v_event_types text[];
    v_insert_payload text;
BEGIN
    SELECT q.queue_id INTO v_queue_id
    FROM pgq.queue AS q
    WHERE q.queue_name = 'cnpg_londiste_functional';
    IF v_queue_id IS NULL THEN
        RAISE EXCEPTION 'Londiste queue was not created';
    END IF;

    EXECUTE format(
        'SELECT array_agg(ev_type ORDER BY ev_id) FROM pgq.event_%s WHERE ev_type IN (''I:id'', ''U:id'', ''D:id'')',
        v_queue_id
    ) INTO v_event_types;
    IF v_event_types IS DISTINCT FROM ARRAY['I:id', 'U:id', 'D:id']::text[] THEN
        RAISE EXCEPTION 'Londiste did not capture insert/update/delete events: %', v_event_types;
    END IF;

    EXECUTE format(
        'SELECT ev_data FROM pgq.event_%s WHERE ev_type = ''I:id'' ORDER BY ev_id DESC LIMIT 1',
        v_queue_id
    ) INTO v_insert_payload;
    IF v_insert_payload IS DISTINCT FROM 'id=1&value=inserted' THEN
        RAISE EXCEPTION 'Londiste insert event payload was unexpected: %', v_insert_payload;
    END IF;
END
$$;
