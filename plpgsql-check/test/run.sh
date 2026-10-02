#!/bin/sh
set -eu
cd "$(dirname "$0")/upstream"
exec "$PG_REGRESS" \
  --inputdir=. --expecteddir=. --outputdir="$TEST_OUTPUT" \
  --dbname=pl_regression \
  plpgsql_check_passive plpgsql_check_active plpgsql_check_active-18 plpgsql_check_passive-18 plpgsql_check_profiler plpgsql_pragma_generator plpgsql_check_stmt_walker plpgsql_check_pragma plpgsql_check_comment_options plpgsql_check_parser plpgsql_check_profiler_local plpgsql_check_profiler_queryid plpgsql_check_profiler_ctrl plpgsql_check_tablefunc plpgsql_check_tracer plpgsql_check_report plpgsql_check_stmtwalk plpgsql_check_expr_walk plpgsql_check_assign plpgsql_check_catalog plpgsql_check_check_function plpgsql_check_pldbgapi3 plpgsql_check_nocrash plpgsql_check_nocrash_unstable_01
