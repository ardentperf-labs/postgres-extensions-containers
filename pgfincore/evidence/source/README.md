# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-pgfincore` in the disposable Trixie CNPG inspection container.

Source descriptor: `pgfincore_1.4.0-1.pgdg13+1.dsc`, SHA256 `ec95b93979796c64219943f62ff5f156ac533d59b60cc9946d334bfb4a06dd6b`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`pgfincore-pgfincore-243f574/Makefile`:

```make
MODULES      = $(EXTENSION)
MODULEDIR    = $(EXTENSION)
```

