# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-similarity` in the disposable Trixie CNPG inspection container.

Source descriptor: `pg-similarity_1.0-9.pgdg13+1.dsc`, SHA256 `b9b6e6b93d46c5b274143475129781fd8477fce6da0a720431e7bc92f40af11f`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`pg_similarity-pg_similarity_1_0/Makefile`:

```make
MODULE_big = pg_similarity
OBJS = tokenizer.o similarity.o similarity_gin.o \
```

