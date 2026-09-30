Format: 3.0 (quilt)
Source: postgresql-plsh
Binary: postgresql-10-plsh, postgresql-11-plsh, postgresql-12-plsh, postgresql-13-plsh, postgresql-14-plsh, postgresql-15-plsh, postgresql-16-plsh, postgresql-17-plsh, postgresql-18-plsh
Architecture: any
Version: 1.20220917-4.pgdg13+2
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/petere/plsh
Standards-Version: 4.7.2
Vcs-Browser: https://salsa.debian.org/postgresql/postgresql-plsh
Vcs-Git: https://salsa.debian.org/postgresql/postgresql-plsh.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, libpq-dev, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-plsh deb database optional arch=any
 postgresql-11-plsh deb database optional arch=any
 postgresql-12-plsh deb database optional arch=any
 postgresql-13-plsh deb database optional arch=any
 postgresql-14-plsh deb database optional arch=any
 postgresql-15-plsh deb database optional arch=any
 postgresql-16-plsh deb database optional arch=any
 postgresql-17-plsh deb database optional arch=any
 postgresql-18-plsh deb database optional arch=any
Checksums-Sha1:
 d7a8bceb4426fbdbe23ec38d0d351fd8f96fb969 11609 postgresql-plsh_1.20220917.orig.tar.gz
 6d9350c1e53e49da48c9dbeea1c9e66333f58ca9 3780 postgresql-plsh_1.20220917-4.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 4fc926c8a98756fd40a93cf14005b2b408363338775466a9672e8ec810afcadb 11609 postgresql-plsh_1.20220917.orig.tar.gz
 554f08f984d79053ccac6df6dde4c3209e56b6c465d5d4d8592161413fae0e78 3780 postgresql-plsh_1.20220917-4.pgdg13+2.debian.tar.xz
Files:
 229b109905f9a53f3cf1d130c0ee8678 11609 postgresql-plsh_1.20220917.orig.tar.gz
 166199a96bf4e874f3145289a5963c0c 3780 postgresql-plsh_1.20220917-4.pgdg13+2.debian.tar.xz
