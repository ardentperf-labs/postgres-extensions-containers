# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-set-user` in the disposable Trixie CNPG inspection container.

Source descriptor: `postgresql-set-user_4.2.0-1.pgdg13+2.dsc`, SHA256 `2736e16ada0699f65744842b54afc7eb2b861a5977dc19259ff7273d8558c0a2`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`set_user-REL4_2_0/Makefile`:

```make
MODULES = src/set_user
```

