Format: 3.0 (quilt)
Source: postgresql-prioritize
Binary: postgresql-10-prioritize, postgresql-11-prioritize, postgresql-12-prioritize, postgresql-13-prioritize, postgresql-14-prioritize, postgresql-15-prioritize, postgresql-16-prioritize, postgresql-17-prioritize, postgresql-18-prioritize
Architecture: any
Version: 1.0.4-13.pgdg13+1
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: http://pgxn.org/dist/prioritize/
Standards-Version: 4.7.2
Vcs-Browser: https://salsa.debian.org/postgresql/postgresql-prioritize
Vcs-Git: https://salsa.debian.org/postgresql/postgresql-prioritize.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-prioritize deb database optional arch=any
 postgresql-11-prioritize deb database optional arch=any
 postgresql-12-prioritize deb database optional arch=any
 postgresql-13-prioritize deb database optional arch=any
 postgresql-14-prioritize deb database optional arch=any
 postgresql-15-prioritize deb database optional arch=any
 postgresql-16-prioritize deb database optional arch=any
 postgresql-17-prioritize deb database optional arch=any
 postgresql-18-prioritize deb database optional arch=any
Checksums-Sha1:
 6adc68e93fa89bd0bee9ff90c835fdb1f3286176 3978 postgresql-prioritize_1.0.4.orig.tar.gz
 e1da1b1733baac3753dd54695518f7b715319cff 3548 postgresql-prioritize_1.0.4-13.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 7fe2975bf90bafafcd18b2e3fd9b98334c97771778ec957278a0d8739d751000 3978 postgresql-prioritize_1.0.4.orig.tar.gz
 46fa856143de9d5d732047fec4ad175d4e7ab67c8e7daeac005c845dca7b7c74 3548 postgresql-prioritize_1.0.4-13.pgdg13+1.debian.tar.xz
Files:
 b4281307572af7cd6111d9dcc62bc569 3978 postgresql-prioritize_1.0.4.orig.tar.gz
 21b9e59099b6d86d80626dae45459547 3548 postgresql-prioritize_1.0.4-13.pgdg13+1.debian.tar.xz
