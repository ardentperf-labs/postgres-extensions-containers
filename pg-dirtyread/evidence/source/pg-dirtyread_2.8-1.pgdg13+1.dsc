Format: 3.0 (quilt)
Source: pg-dirtyread
Binary: postgresql-10-dirtyread, postgresql-11-dirtyread, postgresql-12-dirtyread, postgresql-13-dirtyread, postgresql-14-dirtyread, postgresql-15-dirtyread, postgresql-16-dirtyread, postgresql-17-dirtyread, postgresql-18-dirtyread
Architecture: any
Version: 2.8-1.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Standards-Version: 4.7.4
Vcs-Browser: https://github.com/df7cb/pg_dirtyread
Vcs-Git: https://github.com/df7cb/pg_dirtyread.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-dirtyread deb database optional arch=any
 postgresql-11-dirtyread deb database optional arch=any
 postgresql-12-dirtyread deb database optional arch=any
 postgresql-13-dirtyread deb database optional arch=any
 postgresql-14-dirtyread deb database optional arch=any
 postgresql-15-dirtyread deb database optional arch=any
 postgresql-16-dirtyread deb database optional arch=any
 postgresql-17-dirtyread deb database optional arch=any
 postgresql-18-dirtyread deb database optional arch=any
Checksums-Sha1:
 4a37a107c1d27b884e003173d19f6130aad9a55d 22090 pg-dirtyread_2.8.orig.tar.gz
 5c41b7a2a807abaa2c9a1c2ba6f396f34e4c8aea 3200 pg-dirtyread_2.8-1.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 25f6a1f23c3b32a25ba2f54b1fb73aba14c085973e4060972bcbe5df1028cab7 22090 pg-dirtyread_2.8.orig.tar.gz
 007c2ab0a653d88eab739cc1ddb2d7dcf53c18408238ccf927adf1d9cbb7473c 3200 pg-dirtyread_2.8-1.pgdg13+1.debian.tar.xz
Files:
 8514fca61693ea14cc683917e08f2325 22090 pg-dirtyread_2.8.orig.tar.gz
 03ccee573fc3144c64ff9134d46f906c 3200 pg-dirtyread_2.8-1.pgdg13+1.debian.tar.xz
