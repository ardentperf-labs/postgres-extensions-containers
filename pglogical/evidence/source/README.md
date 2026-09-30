# Source and linkage review

Retrieved with `apt-get source --download-only postgresql-18-pglogical` from Trixie PGDG on 2026-09-29.

Source Makefile links libpq and optional libintl dynamically; the shipped native modules and PostgreSQL-version compatibility code are versioned together by the PGDG source package. No separate static archive is linked.

Descriptor: `pglogical_2.4.8-1.pgdg13+1.dsc`; SHA256 `06f4f822dc5bed1467ef865397f58778f62a132cc528d03d8ce765743b248582`. Source archive and Debian patch hashes are in that descriptor. Rebuild on PGDG source-package updates and separately update dynamic runtime dependencies.
