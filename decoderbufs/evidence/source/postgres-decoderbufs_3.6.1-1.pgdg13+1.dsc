Format: 3.0 (quilt)
Source: postgres-decoderbufs
Binary: postgresql-14-decoderbufs, postgresql-15-decoderbufs, postgresql-16-decoderbufs, postgresql-17-decoderbufs, postgresql-18-decoderbufs
Architecture: any
Version: 3.6.1-1.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/debezium/postgres-decoderbufs
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/postgres-decoderbufs
Vcs-Git: https://salsa.debian.org/postgresql/postgres-decoderbufs.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, libprotobuf-c-dev, pkgconf, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-14-decoderbufs deb database optional arch=any
 postgresql-15-decoderbufs deb database optional arch=any
 postgresql-16-decoderbufs deb database optional arch=any
 postgresql-17-decoderbufs deb database optional arch=any
 postgresql-18-decoderbufs deb database optional arch=any
Checksums-Sha1:
 8cc6df9afa556bb41737d9d318df633adf39f745 15348 postgres-decoderbufs_3.6.1.orig.tar.gz
 0aa4c17d2fadb850fbb9c7812339800a2c96fe25 3596 postgres-decoderbufs_3.6.1-1.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 bcf3f36b7ea61b9fdc152388d8803bb20796460a51f75db0e888ec9d6d1a53a8 15348 postgres-decoderbufs_3.6.1.orig.tar.gz
 67a09e2c8ffc459143b978fd579d0d230ff83a2ca4053940ff956b976469ee15 3596 postgres-decoderbufs_3.6.1-1.pgdg13+1.debian.tar.xz
Files:
 0558add018164a5cd6192931758e01c8 15348 postgres-decoderbufs_3.6.1.orig.tar.gz
 83ee6d54896b0725e495dba0a8080d0d 3596 postgres-decoderbufs_3.6.1-1.pgdg13+1.debian.tar.xz
