CREATE EXTENSION prioritize;

-- Default priority is of course 0, but some Debian buildds run at 10
SELECT get_backend_priority(pg_backend_pid()) BETWEEN 0 AND 10 AS get_backend_priority;
SELECT set_backend_priority(pg_backend_pid(), -5);
SET client_min_messages = warning;
SELECT set_backend_priority(pg_backend_pid(), 15);
RESET client_min_messages;
SELECT get_backend_priority(pg_backend_pid());

SELECT get_backend_priority(1);
SELECT set_backend_priority(1, 5);
