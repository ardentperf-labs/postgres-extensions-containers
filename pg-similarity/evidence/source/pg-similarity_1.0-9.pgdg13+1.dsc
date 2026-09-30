Format: 3.0 (quilt)
Source: pg-similarity
Binary: postgresql-10-similarity, postgresql-11-similarity, postgresql-12-similarity, postgresql-13-similarity, postgresql-14-similarity, postgresql-15-similarity, postgresql-16-similarity, postgresql-17-similarity, postgresql-18-similarity
Architecture: any
Version: 1.0-9.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/eulerto/pg_similarity
Standards-Version: 4.7.2
Vcs-Browser: https://salsa.debian.org/postgresql/pg-similarity
Vcs-Git: https://salsa.debian.org/postgresql/pg-similarity.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-similarity deb database optional arch=any
 postgresql-11-similarity deb database optional arch=any
 postgresql-12-similarity deb database optional arch=any
 postgresql-13-similarity deb database optional arch=any
 postgresql-14-similarity deb database optional arch=any
 postgresql-15-similarity deb database optional arch=any
 postgresql-16-similarity deb database optional arch=any
 postgresql-17-similarity deb database optional arch=any
 postgresql-18-similarity deb database optional arch=any
Checksums-Sha1:
 aca9e8f5b8c0b64310785f46c7732f63ae736ec6 57558 pg-similarity_1.0.orig.tar.gz
 37f33df539e2f1df1e33c9ca9a5d6c75e32911d4 5004 pg-similarity_1.0-9.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 0d74e5c6ba3dd753da8bb55293ebb0f05484eab342af5c2ee1fd03a1cd876276 57558 pg-similarity_1.0.orig.tar.gz
 ef293f1b33f780f95903f6bb56d9949bd18e353b0fefc76cf562d31e85aad104 5004 pg-similarity_1.0-9.pgdg13+1.debian.tar.xz
Files:
 e8b67f4a4092c19ec10c05bf1f1b157b 57558 pg-similarity_1.0.orig.tar.gz
 ddda4e66549ac99f05b590e8486ef000 5004 pg-similarity_1.0-9.pgdg13+1.debian.tar.xz
