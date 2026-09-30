# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-plsh` in the disposable Trixie CNPG inspection container.

Source descriptor: `postgresql-plsh_1.20220917-4.pgdg13+2.dsc`, SHA256 `ccd906e9dadfd6e89f6c58c3bb3597f8f28513d6c4172de3e6c5a4063b5477d7`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`plsh-1.20220917/Makefile`:

```make
MODULE_big = plsh
OBJS = plsh.o
```

