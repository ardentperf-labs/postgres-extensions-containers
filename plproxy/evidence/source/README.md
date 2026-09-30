# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-plproxy` in the disposable Trixie CNPG inspection container.

Source descriptor: `postgresql-plproxy_2.12.0-1.pgdg13+2.dsc`, SHA256 `cb9e2da721207597e1a2b0e4e9485475156a302e6051be479e482b3797da8099`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`plproxy-plproxy-497b92e/Makefile`:

```make
MODULE_big = $(EXTENSION)
OBJS = src/scanner.o src/parser.tab.o $(SRCS:.c=.o)
SHLIB_LINK = -L$(PQLIB) -lpq
SHLIB_LINK += -lws2_32 -lpgport
$(OBJS): $(HDRS)
```

