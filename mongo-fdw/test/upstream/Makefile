# mongo_fdw/Makefile
#
# Portions Copyright (c) 2004-2025, EnterpriseDB Corporation.
# Portions Copyright © 2012–2014 Citus Data, Inc.
#

MODULE_big = mongo_fdw

#
# We assume we are running on a POSIX compliant system (Linux, OSX). If you are
# on another platform, change env_posix.os in MONGO_OBJS with the appropriate
# environment object file.
#
LIBJSON = json-c
LIBJSON_OBJS =  $(LIBJSON)/json_util.o $(LIBJSON)/json_object.o $(LIBJSON)/json_tokener.o \
                                $(LIBJSON)/json_object_iterator.o $(LIBJSON)/printbuf.o $(LIBJSON)/linkhash.o \
                                $(LIBJSON)/arraylist.o $(LIBJSON)/random_seed.o $(LIBJSON)/debug.o $(LIBJSON)/strerror_override.o

# to -I/usr/include/mongoc-2.1.2 also add -I/usr/include/mongoc-2.1.2/mongoc
MONGO_INCLUDE = $(shell pkg-config --cflags libmongoc-1.0 libbson-1.0 | sed -e 's;\(-I/usr/include/\([a-z]*\)-[^ ]*\);\1 \1/\2;g') \
                $(shell pkg-config --cflags mongoc2 | sed -e 's;\(-I/usr/include/\([a-z]*\)-[^ ]*\);\1 \1/\2;g')
PG_CPPFLAGS = --std=c99 $(MONGO_INCLUDE) $(shell pkg-config --cflags json-c)
SHLIB_LINK = $(shell pkg-config --libs libmongoc-1.0 libbson-1.0) \
             $(shell pkg-config --libs mongoc2) \
             $(shell pkg-config --libs json-c)

OBJS = connection.o option.o mongo_wrapper.o mongo_fdw.o mongo_query.o deparse.o


EXTENSION = mongo_fdw
DATA = mongo_fdw--1.0.sql  mongo_fdw--1.1.sql mongo_fdw--1.0--1.1.sql

REGRESS = server_options connection_validation dml select pushdown join_pushdown aggregate_pushdown limit_offset_pushdown
REGRESS_OPTS = --load-extension=$(EXTENSION)

ifdef USE_PGXS
#
# Users need to specify their Postgres installation path through pg_config. For
# example: /usr/local/pgsql/bin/pg_config or /usr/lib/postgresql/9.1/bin/pg_config
#

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

ifndef MAJORVERSION
    MAJORVERSION := $(basename $(VERSION))
endif

ifeq (,$(findstring $(MAJORVERSION), 13 14 15 16 17 18))
    $(error PostgreSQL 13, 14, 15, 16, 17, or 18 is required to compile this extension)
endif

else
subdir = contrib/mongo_fdw
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
