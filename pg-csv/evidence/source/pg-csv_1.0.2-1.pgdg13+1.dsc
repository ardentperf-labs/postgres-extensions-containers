Format: 3.0 (quilt)
Source: pg-csv
Binary: postgresql-12-pg-csv, postgresql-13-pg-csv, postgresql-14-pg-csv, postgresql-15-pg-csv, postgresql-16-pg-csv, postgresql-17-pg-csv, postgresql-18-pg-csv
Architecture: any
Version: 1.0.2-1.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/PostgREST/pg_csv/
Standards-Version: 4.7.3
Vcs-Browser: https://salsa.debian.org/postgresql/pg-csv
Vcs-Git: https://salsa.debian.org/postgresql/pg-csv.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: architecture-is-64-bit <!pkg.postgresql.32-bit>, debhelper-compat (= 13), libicu-dev, postgresql-all <!nocheck>, postgresql-server-dev-all (>= 217~)
Package-List:
 postgresql-12-pg-csv deb database optional arch=any
 postgresql-13-pg-csv deb database optional arch=any
 postgresql-14-pg-csv deb database optional arch=any
 postgresql-15-pg-csv deb database optional arch=any
 postgresql-16-pg-csv deb database optional arch=any
 postgresql-17-pg-csv deb database optional arch=any
 postgresql-18-pg-csv deb database optional arch=any
Checksums-Sha1:
 b1942272fbc198d7d47af840166eb8954fc81515 13245 pg-csv_1.0.2.orig.tar.gz
 51cb3978c6ed87951e7cac0c1500c992f792c5f8 2296 pg-csv_1.0.2-1.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 e97ee6d8699137bf11cc0b73814b1d255aaf72f3867df42e8c283405bd3e2c4f 13245 pg-csv_1.0.2.orig.tar.gz
 da258a032bedb1b8037b3704146953d8d880e3a658b493831d5bce28296eef99 2296 pg-csv_1.0.2-1.pgdg13+1.debian.tar.xz
Files:
 362d43d0d7bd5a01a4047fadff83ff44 13245 pg-csv_1.0.2.orig.tar.gz
 17d823d942bd2533383e0eef27db1ce7 2296 pg-csv_1.0.2-1.pgdg13+1.debian.tar.xz
