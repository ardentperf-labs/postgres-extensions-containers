Format: 3.0 (quilt)
Source: pgnodemx
Binary: postgresql-10-pgnodemx, postgresql-11-pgnodemx, postgresql-12-pgnodemx, postgresql-13-pgnodemx, postgresql-14-pgnodemx, postgresql-15-pgnodemx, postgresql-16-pgnodemx, postgresql-17-pgnodemx, postgresql-18-pgnodemx
Architecture: any
Version: 2.0.1-1.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/pgnodemx/pgnodemx
Standards-Version: 4.7.2
Vcs-Browser: https://salsa.debian.org/postgresql/pgnodemx
Vcs-Git: https://salsa.debian.org/postgresql/pgnodemx.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, libkrb5-dev, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-pgnodemx deb database optional arch=any
 postgresql-11-pgnodemx deb database optional arch=any
 postgresql-12-pgnodemx deb database optional arch=any
 postgresql-13-pgnodemx deb database optional arch=any
 postgresql-14-pgnodemx deb database optional arch=any
 postgresql-15-pgnodemx deb database optional arch=any
 postgresql-16-pgnodemx deb database optional arch=any
 postgresql-17-pgnodemx deb database optional arch=any
 postgresql-18-pgnodemx deb database optional arch=any
Checksums-Sha1:
 812e93756ba4d6ca7e355d9db7bda34bab47e70c 53977 pgnodemx_2.0.1.orig.tar.gz
 e01e4cffd1f7750270a54e064afc678fa04f45a5 3524 pgnodemx_2.0.1-1.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 d540207d8220040923324c3eaeb0b7f3d9850b580ba02655e7e25d67d82a5821 53977 pgnodemx_2.0.1.orig.tar.gz
 f1def276eb42f31cee12e7f0a7e2f9c0db7fdbbfd877d152094828da1969997b 3524 pgnodemx_2.0.1-1.pgdg13+1.debian.tar.xz
Files:
 aa764829ae6e008ad232907c75d232eb 53977 pgnodemx_2.0.1.orig.tar.gz
 ee5fded596308915e75945c793772a17 3524 pgnodemx_2.0.1-1.pgdg13+1.debian.tar.xz
