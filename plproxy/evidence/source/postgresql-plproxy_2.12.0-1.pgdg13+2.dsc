Format: 3.0 (quilt)
Source: postgresql-plproxy
Binary: postgresql-10-plproxy, postgresql-11-plproxy, postgresql-12-plproxy, postgresql-13-plproxy, postgresql-14-plproxy, postgresql-15-plproxy, postgresql-16-plproxy, postgresql-17-plproxy, postgresql-18-plproxy
Architecture: any
Version: 2.12.0-1.pgdg13+2
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>, Peter Eisentraut <petere@debian.org>,
Homepage: https://plproxy.github.io/
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/postgresql-plproxy
Vcs-Git: https://salsa.debian.org/postgresql/postgresql-plproxy.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common, postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, bison, flex, postgresql-server-dev-all (>= 217~)
Package-List:
 postgresql-10-plproxy deb database optional arch=any
 postgresql-11-plproxy deb database optional arch=any
 postgresql-12-plproxy deb database optional arch=any
 postgresql-13-plproxy deb database optional arch=any
 postgresql-14-plproxy deb database optional arch=any
 postgresql-15-plproxy deb database optional arch=any
 postgresql-16-plproxy deb database optional arch=any
 postgresql-17-plproxy deb database optional arch=any
 postgresql-18-plproxy deb database optional arch=any
Checksums-Sha1:
 5f1821812241b8b3befcf0b8661817fab32b3646 78888 postgresql-plproxy_2.12.0.orig.tar.gz
 13c2cd2e5417b92fd135c1ee09b1358d9247c0e9 4668 postgresql-plproxy_2.12.0-1.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 cd486a09beb90f368a217ecb9e9f5eb8e1ef80cb684a06c16a114d3458a6def8 78888 postgresql-plproxy_2.12.0.orig.tar.gz
 d21421174a4fd2af10c3f562f6fe28e48b3466793219fb766f5106a00367d1ed 4668 postgresql-plproxy_2.12.0-1.pgdg13+2.debian.tar.xz
Files:
 2076a49f8947116c72d54a4f28e920bc 78888 postgresql-plproxy_2.12.0.orig.tar.gz
 9dd6104e972f11609f092077c8c50170 4668 postgresql-plproxy_2.12.0-1.pgdg13+2.debian.tar.xz
