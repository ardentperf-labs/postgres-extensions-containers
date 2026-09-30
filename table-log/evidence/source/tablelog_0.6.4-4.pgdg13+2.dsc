Format: 3.0 (quilt)
Source: tablelog
Binary: postgresql-10-tablelog, postgresql-11-tablelog, postgresql-12-tablelog, postgresql-13-tablelog, postgresql-14-tablelog, postgresql-15-tablelog, postgresql-16-tablelog, postgresql-17-tablelog, postgresql-18-tablelog
Architecture: any
Version: 0.6.4-4.pgdg13+2
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/df7cb/table_log
Standards-Version: 4.7.2
Vcs-Browser: https://github.com/df7cb/table_log
Vcs-Git: https://github.com/df7cb/table_log.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-tablelog deb database optional arch=any
 postgresql-11-tablelog deb database optional arch=any
 postgresql-12-tablelog deb database optional arch=any
 postgresql-13-tablelog deb database optional arch=any
 postgresql-14-tablelog deb database optional arch=any
 postgresql-15-tablelog deb database optional arch=any
 postgresql-16-tablelog deb database optional arch=any
 postgresql-17-tablelog deb database optional arch=any
 postgresql-18-tablelog deb database optional arch=any
Checksums-Sha1:
 2f4387b0f032549ee20f04fd02a6c549bc098e78 25637 tablelog_0.6.4.orig.tar.gz
 e0d206294c704b2ab8e26f64d6e27c353c6bdc0a 2028 tablelog_0.6.4-4.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 80c5fbfa162d2e856609468867474440006025b055c523cf03d383e7138aacb2 25637 tablelog_0.6.4.orig.tar.gz
 17f9353928ef290532e3ba9cd924d3ff5ff564a93ce9784cc4a3260a34ed9389 2028 tablelog_0.6.4-4.pgdg13+2.debian.tar.xz
Files:
 163b2101684079c1dde2f1b1f655087e 25637 tablelog_0.6.4.orig.tar.gz
 6948db18e204bdcf4187dd2e901d7510 2028 tablelog_0.6.4-4.pgdg13+2.debian.tar.xz
