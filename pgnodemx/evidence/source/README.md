# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-pgnodemx` in the disposable Trixie CNPG inspection container.

Source descriptor: `pgnodemx_2.0.1-1.pgdg13+1.dsc`, SHA256 `7a7b3f1bdd3398f57a5d170fd73f1a2e15f7e0c83acf899f1e5efb80d286fdb1`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`pgnodemx-2.0.1/Makefile`:

```make
MODULE_big	= pgnodemx
OBJS		= pgnodemx.o cgroup.o envutils.o fileutils.o genutils.o kdapi.o parseutils.o procfunc.o
```

