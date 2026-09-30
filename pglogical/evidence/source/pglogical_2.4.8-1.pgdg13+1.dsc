Format: 3.0 (quilt)
Source: pglogical
Binary: postgresql-11-pglogical, postgresql-12-pglogical, postgresql-13-pglogical, postgresql-14-pglogical, postgresql-15-pglogical, postgresql-16-pglogical, postgresql-17-pglogical, postgresql-18-pglogical
Architecture: any
Version: 2.4.8-1.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Michael Banck <mbanck@debian.org>, Marco Nenciarini <mnencia@debian.org>,
Homepage: https://github.com/2ndQuadrant/pglogical
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/pglogical
Vcs-Git: https://salsa.debian.org/postgresql/pglogical.git
Testsuite: autopkgtest
Testsuite-Triggers: libipc-run-perl, libtap-parser-sourcehandler-pgtap-perl, postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, krb5-multidev, libedit-dev, libkrb5-dev, liblz4-dev, libnuma-dev, libpam0g-dev, libreadline-dev, libselinux-dev [linux-any], libssl-dev, libxml2-dev, libxslt1-dev, libzstd-dev, postgresql-server-dev-all (>= 217~), zlib1g-dev
Package-List:
 postgresql-11-pglogical deb database optional arch=any
 postgresql-12-pglogical deb database optional arch=any
 postgresql-13-pglogical deb database optional arch=any
 postgresql-14-pglogical deb database optional arch=any
 postgresql-15-pglogical deb database optional arch=any
 postgresql-16-pglogical deb database optional arch=any
 postgresql-17-pglogical deb database optional arch=any
 postgresql-18-pglogical deb database optional arch=any
Checksums-Sha1:
 a96e19d58ef7668e82b9e7fbba0806554af6e69f 290300 pglogical_2.4.8.orig.tar.gz
 1efb60f6ea5eae29da8bc9735229af61f344cf42 179740 pglogical_2.4.8-1.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 b93dc45a45bcc3c5c3e8f432bbdb1121f8ecf336dc2d4611a2eed0e3e46ed1a1 290300 pglogical_2.4.8.orig.tar.gz
 8177776e4ada6b2a4af85d3e1d801f897a7114302c23f985552317799dd5ffda 179740 pglogical_2.4.8-1.pgdg13+1.debian.tar.xz
Files:
 c06f1babca032b97605bab641dba74a5 290300 pglogical_2.4.8.orig.tar.gz
 452731d8137f4275d4c232a6d682ce99 179740 pglogical_2.4.8-1.pgdg13+1.debian.tar.xz
