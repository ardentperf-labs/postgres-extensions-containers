Format: 3.0 (quilt)
Source: pg-rewrite
Binary: postgresql-14-pg-rewrite, postgresql-15-pg-rewrite, postgresql-16-pg-rewrite, postgresql-17-pg-rewrite, postgresql-18-pg-rewrite
Architecture: any
Version: 2.2-2.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/cybertec-postgresql/pg_rewrite
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/pg-rewrite
Vcs-Git: https://salsa.debian.org/postgresql/pg-rewrite.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all (>= 217~)
Package-List:
 postgresql-14-pg-rewrite deb database optional arch=any
 postgresql-15-pg-rewrite deb database optional arch=any
 postgresql-16-pg-rewrite deb database optional arch=any
 postgresql-17-pg-rewrite deb database optional arch=any
 postgresql-18-pg-rewrite deb database optional arch=any
Checksums-Sha1:
 0a7a58a49a04f3c21b64d47ddde08fee9e348eb9 57312 pg-rewrite_2.2.orig.tar.gz
 45e467288520d17cf596c84059eb66bb8678d36f 2272 pg-rewrite_2.2-2.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 843351db16f79d024d67ceb9c1e6eaaecbbedc2460c12a084e1c0476fd791e2b 57312 pg-rewrite_2.2.orig.tar.gz
 9cd507fb63f1f9f7e2df0bf59102f3cabe7190978122fdcbb74bcec648547f44 2272 pg-rewrite_2.2-2.pgdg13+1.debian.tar.xz
Files:
 9c9ac9b08387daf214003ed847ce7cd0 57312 pg-rewrite_2.2.orig.tar.gz
 8c0fe32a462411b9a063d90621f0b2f9 2272 pg-rewrite_2.2-2.pgdg13+1.debian.tar.xz
