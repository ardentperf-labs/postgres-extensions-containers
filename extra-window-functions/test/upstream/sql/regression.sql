SELECT CASE
    WHEN setting::integer >= 190000 THEN '19 ..'
    WHEN setting::integer >= 90600 THEN '9.6 .. 18'
    ELSE '.. 9.5' END::text AS version_span
FROM pg_settings WHERE name = 'server_version_num';

CREATE EXTENSION extra_window_functions;

CREATE TABLE things (
    part integer NOT NULL,
    ord integer NOT NULL,
    val integer
);

COPY things FROM stdin;
1	1	64664
1	2	8779
1	3	14005
1	4	57699
1	5	98842
1	6	88563
1	7	70453
1	8	82824
1	9	62453
2	1	\N
2	2	51714
2	3	17096
2	4	41605
2	5	15366
2	6	87359
2	7	98990
2	8	34982
2	9	3343
3	1	21903
3	2	24605
3	3	6242
3	4	24947
3	5	79535
3	6	66903
3	7	42269
3	8	31143
3	9	\N
4	1	\N
4	2	49723
4	3	23958
4	4	80796
4	5	\N
4	6	41066
4	7	72991
4	8	33734
4	9	\N
5	1	\N
5	2	\N
5	3	\N
5	4	\N
5	5	\N
5	6	\N
5	7	\N
5	8	\N
5	9	\N
\.

/* FLIP_FLOP */

SELECT part, ord, val,
       flip_flop(val % 2 = 0) OVER w AS flip_flop_1,
       flip_flop(val % 2 = 0, val % 2 = 1) OVER w AS flip_flop_2
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LAG */

SELECT part, ord, val,
       lag(val) OVER w AS lag,
       lag_ignore_nulls(val) OVER w AS lag_in,
       lag_ignore_nulls(val, 2) OVER w AS lag_in_off,
       lag_ignore_nulls(val, 2, -9999999) OVER w AS lag_in_off_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LEAD */

SELECT part, ord, val,
       lead(val) OVER w AS lead,
       lead_ignore_nulls(val) OVER w AS lead_in,
       lead_ignore_nulls(val, 2) OVER w AS lead_in_off,
       lead_ignore_nulls(val, 2, 9999999) OVER w AS lead_in_off_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* FIRST_VALUE */

SELECT part, ord, val,
       first_value(val) OVER w AS fv,
       first_value_ignore_nulls(val) OVER w AS fv_in,
       first_value_ignore_nulls(val, 9999999) OVER w AS fv_in_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* LAST_VALUE */

SELECT part, ord, val,
       last_value(val) OVER w AS lv,
       last_value_ignore_nulls(val) OVER w AS lv_in,
       last_value_ignore_nulls(val, -9999999) OVER w AS lv_in_d
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* NTH_VALUE */

SELECT part, ord, val,
       nth_value(val, 3) OVER w AS nth,
       nth_value_ignore_nulls(val, 3) OVER w AS nth_in
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

SELECT part, ord, val,
       nth_value(val, 3) OVER w AS nth,
       nth_value_from_last(val, 3) OVER w AS nth_fl
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

SELECT part, ord, val,
       nth_value_from_last(val, 3) OVER w AS nth_fl,
       nth_value_from_last_ignore_nulls(val, 3) OVER w AS nth_fl_in
FROM things
WINDOW w AS (PARTITION BY part ORDER BY ord ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
ORDER BY part, ord;

/* COUNT_TIES / AVG_RANK */

SELECT part, val,
       rank()       OVER w AS rank,
       dense_rank() OVER w AS dense_rank,
       count_ties() OVER w AS count_ties,
       avg_rank()   OVER w AS avg_rank
FROM things
WINDOW w AS (PARTITION BY part ORDER BY val)
ORDER BY part, val, ord;

CREATE TABLE scores (name text, score integer);

COPY scores FROM stdin;
alice	90
bob	80
carol	80
dave	80
eve	70
frank	70
grace	60
\.

SELECT name, score,
       rank()       OVER w AS rank,
       dense_rank() OVER w AS dense_rank,
       count_ties() OVER w AS count_ties,
       avg_rank()   OVER w AS avg_rank
FROM scores
WINDOW w AS (ORDER BY score DESC)
ORDER BY score DESC, name;

DROP TABLE scores;

/* AVG_PERCENT_RANK */

SELECT val,
       percent_rank()     OVER w AS percent_rank,
       avg_percent_rank() OVER w AS avg_percent_rank
FROM (VALUES (10), (20), (20), (20), (30)) AS t(val)
WINDOW w AS (ORDER BY val)
ORDER BY val;

/* GROUP_NUMBER (sessionization and gaps-and-islands) */

SELECT ord, grp,
       group_number(new_session) OVER w AS session
FROM (
    SELECT ord, grp,
           (ord - lag(ord) OVER (PARTITION BY grp ORDER BY ord)) > 1 AS new_session
    FROM (VALUES (1, 1), (2, 1), (5, 1), (6, 1), (10, 1),
                 (1, 2), (2, 2), (3, 2)) AS t(ord, grp)
) s
WINDOW w AS (PARTITION BY grp ORDER BY ord)
ORDER BY grp, ord;

/* EMA */

SELECT ord, val,
       ema(val, 0.5) OVER w AS ema
FROM (VALUES (1, 10.0), (2, 20.0), (3, 30.0), (4, 30.0), (5, NULL)) AS t(ord, val)
WINDOW w AS (ORDER BY ord)
ORDER BY ord;

/* INTERPOLATE */

SELECT ord, val,
       interpolate(val) OVER w AS interpolated
FROM (VALUES (1, NULL), (2, 10.0), (3, NULL), (4, NULL),
             (5, 40.0), (6, NULL)) AS t(ord, val)
WINDOW w AS (ORDER BY ord)
ORDER BY ord;

/* RUN_LENGTH / RUN_POSITION */

SELECT ord, val,
       run_length(val)   OVER w AS run_length,
       run_position(val) OVER w AS run_position
FROM (VALUES (1, 'x'), (2, 'x'), (3, 'y'), (4, 'x'),
             (5, 'x'), (6, 'x'), (7, NULL), (8, NULL)) AS t(ord, val)
WINDOW w AS (ORDER BY ord)
ORDER BY ord;

/* MOST_COMMON */

SELECT ord, val,
       most_common(val) OVER ()  AS mode_all,
       most_common(val) OVER w   AS mode_running
FROM (VALUES (1, 'a'), (2, 'b'), (3, 'b'), (4, 'a'), (5, 'a')) AS t(ord, val)
WINDOW w AS (ORDER BY ord)
ORDER BY ord;

DROP TABLE things;

DROP EXTENSION extra_window_functions;
