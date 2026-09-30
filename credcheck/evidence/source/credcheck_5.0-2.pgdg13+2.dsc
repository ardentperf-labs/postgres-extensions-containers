Format: 3.0 (quilt)
Source: credcheck
Binary: postgresql-12-credcheck, postgresql-13-credcheck, postgresql-14-credcheck, postgresql-15-credcheck, postgresql-16-credcheck, postgresql-17-credcheck, postgresql-18-credcheck
Architecture: any
Version: 5.0-2.pgdg13+2
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/MigOpsRepos/credcheck
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/credcheck
Vcs-Git: https://salsa.debian.org/postgresql/credcheck.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, libkrb5-dev, postgresql-all <!nocheck>, postgresql-server-dev-all (>= 217~)
Package-List:
 postgresql-12-credcheck deb database optional arch=any
 postgresql-13-credcheck deb database optional arch=any
 postgresql-14-credcheck deb database optional arch=any
 postgresql-15-credcheck deb database optional arch=any
 postgresql-16-credcheck deb database optional arch=any
 postgresql-17-credcheck deb database optional arch=any
 postgresql-18-credcheck deb database optional arch=any
Checksums-Sha1:
 b9dc4f1656f33e63ab553cec4d69c72eb927a457 46787 credcheck_5.0.orig.tar.gz
 c02fe3f2be8f888c1bebc983558b93b6f90ce1d2 3596 credcheck_5.0-2.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 5459c9a3f7163e8ec86995fc68d3e4c06819ee6de064cb37b989b18caa4f0613 46787 credcheck_5.0.orig.tar.gz
 491837925f007a2f3cee812cced254b06d11e07a51d302dc3331bacf8a9219fc 3596 credcheck_5.0-2.pgdg13+2.debian.tar.xz
Files:
 1653a0722129852dfb6e2166613d0d1a 46787 credcheck_5.0.orig.tar.gz
 a727510830937a04065644cb0190fae1 3596 credcheck_5.0-2.pgdg13+2.debian.tar.xz
