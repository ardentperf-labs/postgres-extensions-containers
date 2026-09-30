Format: 3.0 (quilt)
Source: postgresql-set-user
Binary: postgresql-13-set-user, postgresql-14-set-user, postgresql-15-set-user, postgresql-16-set-user, postgresql-17-set-user, postgresql-18-set-user
Architecture: any
Version: 4.2.0-1.pgdg13+2
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Christoph Berg <myon@debian.org>,
Homepage: https://github.com/pgaudit/set_user
Standards-Version: 4.7.2
Vcs-Browser: https://salsa.debian.org/postgresql/postgresql-set-user
Vcs-Git: https://salsa.debian.org/postgresql/postgresql-set-user.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-13-set-user deb database optional arch=any
 postgresql-14-set-user deb database optional arch=any
 postgresql-15-set-user deb database optional arch=any
 postgresql-16-set-user deb database optional arch=any
 postgresql-17-set-user deb database optional arch=any
 postgresql-18-set-user deb database optional arch=any
Checksums-Sha1:
 4b8ed81141258b7b7131c284a6b052a0535940b2 22671 postgresql-set-user_4.2.0.orig.tar.gz
 b8eb4124a3c99e3c8696b7810528a8457ef57d10 3000 postgresql-set-user_4.2.0-1.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 87db7f1baee9149bfb88547415644d0855bf975ad22d3d17de7e01901e35850c 22671 postgresql-set-user_4.2.0.orig.tar.gz
 f2772d1f77ac7ef48afd35015991af402b23486359a67a1412b16a7e0f5809c7 3000 postgresql-set-user_4.2.0-1.pgdg13+2.debian.tar.xz
Files:
 f392f2a4776c413369e7948d92baf6fb 22671 postgresql-set-user_4.2.0.orig.tar.gz
 487b5c6966abd43139190c76e4d20ebd 3000 postgresql-set-user_4.2.0-1.pgdg13+2.debian.tar.xz
