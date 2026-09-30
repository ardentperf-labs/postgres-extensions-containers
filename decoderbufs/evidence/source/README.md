# Source and linkage review

Retrieved with `apt-get source --download-only postgresql-18-decoderbufs` from Trixie PGDG on 2026-09-29.

Source Makefile links libprotobuf-c through pkg-config and compiles decoderbufs.c plus generated pg_logicaldec.pb-c.c. The generated serialization code follows the decoderbufs source version; protobuf-c is dynamically linked. No PostGIS library or separate static archive is linked by this release.

Descriptor: `postgres-decoderbufs_3.6.1-1.pgdg13+1.dsc`; SHA256 `55e782a22c65d18e992d13390fd347254fb315dc536492ca17d0ba25453365f0`. Source archive and Debian patch hashes are in that descriptor. Rebuild on PGDG source-package updates and separately update dynamic runtime dependencies.
