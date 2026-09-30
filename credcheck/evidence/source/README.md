# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-credcheck` in the disposable Trixie CNPG inspection container.

Source descriptor: `credcheck_5.0-2.pgdg13+2.dsc`, SHA256 `5bd529ad07873da23ed2e8c27b12b9cac1e843c5f88a8cc7459034d072eb4f13`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`HexaCluster-credcheck-2df0cbd/Makefile`:

```make
#SHLIB_LINK = -lcrack
MODULE_big = credcheck
OBJS = credcheck.o $(WIN32RES)
```

