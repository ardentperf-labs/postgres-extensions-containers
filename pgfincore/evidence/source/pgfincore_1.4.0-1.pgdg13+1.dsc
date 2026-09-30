Format: 3.0 (quilt)
Source: pgfincore
Binary: postgresql-10-pgfincore, postgresql-11-pgfincore, postgresql-12-pgfincore, postgresql-13-pgfincore, postgresql-14-pgfincore, postgresql-15-pgfincore, postgresql-16-pgfincore, postgresql-17-pgfincore, postgresql-18-pgfincore
Architecture: any
Version: 1.4.0-1.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Cédric Villemain <cedric@villemain.org>, Dimitri Fontaine <dim@tapoueh.org>, Christoph Berg <myon@debian.org>,
Homepage: http://villemain.org/projects/pgfincore
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/pgfincore
Vcs-Git: https://salsa.debian.org/postgresql/pgfincore.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-pgfincore deb database optional arch=any
 postgresql-11-pgfincore deb database optional arch=any
 postgresql-12-pgfincore deb database optional arch=any
 postgresql-13-pgfincore deb database optional arch=any
 postgresql-14-pgfincore deb database optional arch=any
 postgresql-15-pgfincore deb database optional arch=any
 postgresql-16-pgfincore deb database optional arch=any
 postgresql-17-pgfincore deb database optional arch=any
 postgresql-18-pgfincore deb database optional arch=any
Checksums-Sha1:
 f28b3e91b61304dc53a55339f48b09dacf25f206 15564 pgfincore_1.4.0.orig.tar.gz
 c5b4a984067bc93779ea40069751ef7a8f66e031 3488 pgfincore_1.4.0-1.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 b60835c2e7ef97e1ca09aa528d9de065241e61e0d390b60553e72ac757f0efa9 15564 pgfincore_1.4.0.orig.tar.gz
 17355ee6133d21264b53fd5c68c6214e3e5c7764f9c18b704815cff57f0a482a 3488 pgfincore_1.4.0-1.pgdg13+1.debian.tar.xz
Files:
 3f5c82fc9292342f532b7143c3da3c6b 15564 pgfincore_1.4.0.orig.tar.gz
 8fc02fbe3adb9814bd79c73efcd09a3e 3488 pgfincore_1.4.0-1.pgdg13+1.debian.tar.xz
