# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-pgextwlist` in the disposable Trixie CNPG inspection container.

Source descriptor: `pgextwlist_1.20-1.pgdg13+2.dsc`, SHA256 `cfc5b5f57e4d5a274c797048359d0263703faae6f45b7e7c4891baf10b3c6e3c`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`dimitri-pgextwlist-ab92a4c/Makefile`:

```make
MODULE_big = pgextwlist
OBJS       = utils.o pgextwlist.o
```

