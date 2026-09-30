# Source linkage review

PGDG source was retrieved with `apt-get source --download-only postgresql-18-tablelog` in the disposable Trixie CNPG inspection container.

Source descriptor: `tablelog_0.6.4-4.pgdg13+2.dsc`, SHA256 `0f96b1caf06c90b84378a93adc19c2ee51a983e8371b873d7e8f4060d4ece362`.

Reviewed Makefile linkage and the source copyright notices. No separately versioned static third-party library archive is linked by these build rules. Extension-owned and adapted source code is accounted for by the PGDG source version and hashes in this descriptor; rebuild on source-package updates. Generated parser code, where present, belongs to that same source build. Dynamic dependencies are recorded in the per-distro `ldd.txt` and runtime manifest.

`table_log-0.6.4/Makefile`:

```make
MODULES = table_log
```

