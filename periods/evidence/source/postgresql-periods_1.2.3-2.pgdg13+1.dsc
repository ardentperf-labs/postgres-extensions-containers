Format: 3.0 (quilt)
Source: postgresql-periods
Binary: postgresql-10-periods, postgresql-11-periods, postgresql-12-periods, postgresql-13-periods, postgresql-14-periods, postgresql-15-periods, postgresql-16-periods, postgresql-17-periods, postgresql-18-periods
Architecture: any
Version: 1.2.3-2.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/xocolatl/periods
Standards-Version: 4.7.2
Vcs-Browser: https://github.com/xocolatl/periods
Vcs-Git: https://github.com/xocolatl/periods.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-periods deb database optional arch=any
 postgresql-11-periods deb database optional arch=any
 postgresql-12-periods deb database optional arch=any
 postgresql-13-periods deb database optional arch=any
 postgresql-14-periods deb database optional arch=any
 postgresql-15-periods deb database optional arch=any
 postgresql-16-periods deb database optional arch=any
 postgresql-17-periods deb database optional arch=any
 postgresql-18-periods deb database optional arch=any
Checksums-Sha1:
 519e0f7ab4ed3dc4e9278444557c04a26a8341c8 120940 postgresql-periods_1.2.3.orig.tar.gz
 009c236c514f54cb9656c81705a6cc309d324f55 2592 postgresql-periods_1.2.3-2.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 2104b4a1ecf682ef499a13119ecdf5e511839d6164bfb18d04db014efa922831 120940 postgresql-periods_1.2.3.orig.tar.gz
 29ce29dd91b704d589921b1a9ba15d64d9c08a18a2c8806793f97488753768b2 2592 postgresql-periods_1.2.3-2.pgdg13+1.debian.tar.xz
Files:
 8817f596b45da810d542c216a5ad28f6 120940 postgresql-periods_1.2.3.orig.tar.gz
 8891878512de27ddbe8cb5c4ac36c88b 2592 postgresql-periods_1.2.3-2.pgdg13+1.debian.tar.xz
