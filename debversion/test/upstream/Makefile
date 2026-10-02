MODULE_big = debversion
EXTENSION = debversion
OBJS = debversion.o
DATA = \
	debversion--unpackaged--1.0.5.sql	\
	debversion--1.0.5--1.0.6.sql		\
	debversion--1.0.6--1.0.7.sql		\
	debversion--1.0.7--1.0.8.sql		\
	debversion--1.0.8--1.1.sql		\
	debversion--1.1--1.2.sql		\
	debversion--1.2.sql
REGRESS = debversion

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

CXXFLAGS += -fPIC # needed for 9.x-10
LDFLAGS += -lapt-pkg
