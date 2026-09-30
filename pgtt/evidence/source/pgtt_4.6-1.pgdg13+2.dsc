Format: 3.0 (quilt)
Source: pgtt
Binary: postgresql-12-pgtt, postgresql-13-pgtt, postgresql-14-pgtt, postgresql-15-pgtt, postgresql-16-pgtt, postgresql-17-pgtt, postgresql-18-pgtt
Architecture: any
Version: 4.6-1.pgdg13+2
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/darold/pgtt/
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/pgtt
Vcs-Git: https://salsa.debian.org/postgresql/pgtt.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-12-pgtt deb database optional arch=any
 postgresql-13-pgtt deb database optional arch=any
 postgresql-14-pgtt deb database optional arch=any
 postgresql-15-pgtt deb database optional arch=any
 postgresql-16-pgtt deb database optional arch=any
 postgresql-17-pgtt deb database optional arch=any
 postgresql-18-pgtt deb database optional arch=any
Checksums-Sha1:
 ce2dae238193ae59fbc5247ef02e8873d1b60c51 64704 pgtt_4.6.orig.tar.gz
 b7bf6e09c07fe8c1a6e2565be240e7a6cf25ba3d 2400 pgtt_4.6-1.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 0ec89b0290be9a69c0dbdad0e2153f129a114cbd453239c07268cf1d89154ed0 64704 pgtt_4.6.orig.tar.gz
 9f854e7e335eb5a76bc477fbdc29ba622a98c555bf3efd61b592f96982bb5497 2400 pgtt_4.6-1.pgdg13+2.debian.tar.xz
Files:
 93ae682086e21e9c986a881f130491ae 64704 pgtt_4.6.orig.tar.gz
 14e4c4652ec60defef89c4a8fda2fba0 2400 pgtt_4.6-1.pgdg13+2.debian.tar.xz
