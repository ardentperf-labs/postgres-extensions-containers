# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-pg-rewrite` in the disposable Trixie CNPG inspection container.

Source descriptor: `pg-rewrite_2.2-2.pgdg13+1.dsc`, SHA256 `aee4b66550b3e2aeb569fe3651fd4f23a6fa3b78ee75b24ac05acbda5b8f6685`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`cybertec-postgresql-pg_rewrite-97f17b5/Makefile`:

```make
MODULE_big = pg_rewrite
OBJS = pg_rewrite.o concurrent.o $(WIN32RES)
```

