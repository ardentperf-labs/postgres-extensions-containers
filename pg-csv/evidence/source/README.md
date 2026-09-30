# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-pg-csv` in the disposable Trixie CNPG inspection container.

Source descriptor: `pg-csv_1.0.2-1.pgdg13+1.dsc`, SHA256 `19a406f62f11983a1c2de7fa47e6a48c5f0c5a3174130e099395f2c2f22c4749`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`pg_csv-1.0.2/Makefile`:

```make
MODULE_big = $(EXTENSION)
OBJS = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SRC))
OBJS = $(patsubst $(SRC_DIR)/%.c, src/%.o, $(SRC)) # if no BUILD_DIR, just build on src so standard PGXS `make` works
```

