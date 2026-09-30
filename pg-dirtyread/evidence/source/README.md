# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-dirtyread` in the disposable Trixie CNPG inspection container.

Source descriptor: `pg-dirtyread_2.8-1.pgdg13+1.dsc`, SHA256 `18792c3f6178f6bfbe34b8de02006a5763ee2b1e70cb1ab31eb1e5025206bcad`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`df7cb-pg_dirtyread-b2d05be/Makefile`:

```make
MODULE_big = pg_dirtyread
OBJS = pg_dirtyread.o dirtyread_tupconvert.o
```

