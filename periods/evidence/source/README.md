# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-periods` in the disposable Trixie CNPG inspection container.

Source descriptor: `postgresql-periods_1.2.3-2.pgdg13+1.dsc`, SHA256 `862e67185da0bf92d6c51f5754b9d4143335ea7c9ca501d8c759425a2d902e23`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`periods-1.2.3/Makefile`:

```make
MODULES = periods
```

