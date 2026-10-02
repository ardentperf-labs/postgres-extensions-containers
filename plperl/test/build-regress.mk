PG_CONFIG ?= pg_config
MODULE_big = regress
OBJS = regress.o
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
