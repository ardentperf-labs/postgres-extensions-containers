Format: 3.0 (quilt)
Source: pgextwlist
Binary: postgresql-10-pgextwlist, postgresql-11-pgextwlist, postgresql-12-pgextwlist, postgresql-13-pgextwlist, postgresql-14-pgextwlist, postgresql-15-pgextwlist, postgresql-16-pgextwlist, postgresql-17-pgextwlist, postgresql-18-pgextwlist
Architecture: any
Version: 1.20-1.pgdg13+2
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Uploaders:  Dimitri Fontaine <dim@tapoueh.org>, Christoph Berg <myon@debian.org>,
Homepage: https://github.com/dimitri/pgextwlist
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/postgresql/pgextwlist
Vcs-Git: https://salsa.debian.org/postgresql/pgextwlist.git
Testsuite: autopkgtest
Testsuite-Triggers: postgresql-common-dev, postgresql-contrib-10, postgresql-contrib-11, postgresql-contrib-12, postgresql-contrib-13, postgresql-contrib-14, postgresql-contrib-15, postgresql-contrib-16, postgresql-contrib-17, postgresql-contrib-18
Build-Depends: debhelper-compat (= 13), architecture-is-64-bit <!pkg.postgresql.32-bit>, postgresql-all <!nocheck>, postgresql-server-dev-all
Package-List:
 postgresql-10-pgextwlist deb libs optional arch=any
 postgresql-11-pgextwlist deb libs optional arch=any
 postgresql-12-pgextwlist deb libs optional arch=any
 postgresql-13-pgextwlist deb libs optional arch=any
 postgresql-14-pgextwlist deb libs optional arch=any
 postgresql-15-pgextwlist deb libs optional arch=any
 postgresql-16-pgextwlist deb libs optional arch=any
 postgresql-17-pgextwlist deb libs optional arch=any
 postgresql-18-pgextwlist deb libs optional arch=any
Checksums-Sha1:
 4b4c9ac8da83eaa4de7307a46b7e0eacc0142110 22584 pgextwlist_1.20.orig.tar.gz
 b4ec66f2f08af9c9163da32e9512af41874d4c61 3648 pgextwlist_1.20-1.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 bfbe21df88b76571849d070d03a1cb1e6d32d6dd610861fdfca5cc26b321dee0 22584 pgextwlist_1.20.orig.tar.gz
 e9c7f2823de25aaaa5fbaa9f38d68440fc389ad8c9f77a4b92e9e9626995f127 3648 pgextwlist_1.20-1.pgdg13+2.debian.tar.xz
Files:
 0dc8000d75655cb95ceb86673f652c1e 22584 pgextwlist_1.20.orig.tar.gz
 969c997714cb5bc5d219621801535c33 3648 pgextwlist_1.20-1.pgdg13+2.debian.tar.xz
