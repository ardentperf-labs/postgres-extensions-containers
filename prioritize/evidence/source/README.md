# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-prioritize` in the disposable Trixie CNPG inspection container.

Source descriptor: `postgresql-prioritize_1.0.4-13.pgdg13+1.dsc`, SHA256 `fadbf8c7496a3e7ebac82900c2ce0b132a6632323248fad724f6770b3a317d1b`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`prioritize-1.0.4/Makefile`:

```make
MODULES = prioritize
EXTENSION = $(MODULES)
EXTSQL = $(MODULES)--$(EXTVERSION).sql
DATA_built = $(MODULES).sql
DATA = uninstall_$(MODULES).sql
REGRESS = $(MODULES)
SQL_IN = $(MODULES).sql.in
EXTRA_CLEAN = sql/$(MODULES).sql expected/$(MODULES).out
```

