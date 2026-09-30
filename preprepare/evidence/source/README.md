# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-preprepare` in the disposable Trixie CNPG inspection container.

Source descriptor: `preprepare_0.9-10.pgdg13+1.dsc`, SHA256 `3bc52b143340bf66946d5df6fa0f9a5a07e3627e61652ee3ec680542f932680e`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`preprepare-0.9/Makefile`:

```make
MODULES = pre_prepare
```

