Format: 3.0 (quilt)
Source: preprepare
Binary: postgresql-10-preprepare, postgresql-11-preprepare, postgresql-12-preprepare, postgresql-13-preprepare, postgresql-14-preprepare, postgresql-15-preprepare, postgresql-16-preprepare, postgresql-17-preprepare, postgresql-18-preprepare
Architecture: any
Version: 0.9-10.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Dimitri Fontaine <dim@tapoueh.org>, Christoph Berg <myon@debian.org>,
Standards-Version: 4.7.2
Vcs-Browser: https://github.com/dimitri/preprepare
Vcs-Git: https://github.com/dimitri/preprepare.git -b debian
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-preprepare deb database optional arch=any
 postgresql-11-preprepare deb database optional arch=any
 postgresql-12-preprepare deb database optional arch=any
 postgresql-13-preprepare deb database optional arch=any
 postgresql-14-preprepare deb database optional arch=any
 postgresql-15-preprepare deb database optional arch=any
 postgresql-16-preprepare deb database optional arch=any
 postgresql-17-preprepare deb database optional arch=any
 postgresql-18-preprepare deb database optional arch=any
Checksums-Sha1:
 a9a83f8d4ee21bd90f6fa64c5b1b00cbf6b9a4b2 15731 preprepare_0.9.orig.tar.gz
 1528253d5bd8dfda55b27fa28b67e259d88a2e56 3256 preprepare_0.9-10.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 77c03cc0159bfba37e70620185cd383c83c956558a663996df4bee3a439b365e 15731 preprepare_0.9.orig.tar.gz
 6bb1dc976245b8d65db349670ee6c06358fd0a6dd9e23f87a9ed3ad378f4a82f 3256 preprepare_0.9-10.pgdg13+1.debian.tar.xz
Files:
 ee36e1e93193bf05777bfa51783054aa 15731 preprepare_0.9.orig.tar.gz
 f867b4fb4fa1664035f0cdf49f8088cf 3256 preprepare_0.9-10.pgdg13+1.debian.tar.xz
