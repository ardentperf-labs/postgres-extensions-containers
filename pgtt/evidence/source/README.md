# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-pgtt` in the disposable Trixie CNPG inspection container.

Source descriptor: `pgtt_4.6-1.pgdg13+2.dsc`, SHA256 `ada152afffedc827ec418ef6c0efc3b73b4abf3d0a130db5d9991007a51e46db`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`darold-pgtt-fe8b2d5/Makefile`:

```make
PG_LDFLAGS = -L$(libpq_builddir) -lpq
SHLIB_LINK = $(libpq)
MODULES = pgtt
```

