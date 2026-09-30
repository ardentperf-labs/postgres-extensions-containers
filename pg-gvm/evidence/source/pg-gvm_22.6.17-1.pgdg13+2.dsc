Format: 3.0 (quilt)
Source: pg-gvm
Binary: postgresql-11-pg-gvm, postgresql-12-pg-gvm, postgresql-13-pg-gvm, postgresql-14-pg-gvm, postgresql-15-pg-gvm, postgresql-16-pg-gvm, postgresql-17-pg-gvm, postgresql-18-pg-gvm
Architecture: any
Version: 22.6.17-1.pgdg13+2
Maintainer: Debian Security Tools <team+pkg-security@tracker.debian.org>
Uploaders: Sophie Brun <sophie@kali.org>
Homepage: https://github.com/greenbone/pg-gvm
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/pkg-security-team/pg-gvm
Vcs-Git: https://salsa.debian.org/pkg-security-team/pg-gvm.git
Testsuite: autopkgtest
Testsuite-Triggers: libtap-parser-sourcehandler-pgtap-perl, postgresql-11-pgtap, postgresql-12-pgtap, postgresql-13-pgtap, postgresql-14-pgtap, postgresql-15-pgtap, postgresql-16-pgtap, postgresql-17-pgtap, postgresql-18-pgtap, postgresql-common-dev
Build-Depends: cmake (>= 3.0), debhelper-compat (= 13), libical-dev (>= 1.0), libgvm-dev (>= 22.6.0), pkgconf, postgresql-all
Package-List:
 postgresql-11-pg-gvm deb libs optional arch=any
 postgresql-12-pg-gvm deb libs optional arch=any
 postgresql-13-pg-gvm deb libs optional arch=any
 postgresql-14-pg-gvm deb libs optional arch=any
 postgresql-15-pg-gvm deb libs optional arch=any
 postgresql-16-pg-gvm deb libs optional arch=any
 postgresql-17-pg-gvm deb libs optional arch=any
 postgresql-18-pg-gvm deb libs optional arch=any
Checksums-Sha1:
 01deaffa93672b8ce7affa2e5d50442e9be92a75 40746 pg-gvm_22.6.17.orig.tar.gz
 96049dd66b8d0e4a40dd69c5717fb86a5e5cd1d5 14260 pg-gvm_22.6.17-1.pgdg13+2.debian.tar.xz
Checksums-Sha256:
 f63f77dae45d3e128798a8857b4358aa429a509ea5e04f48ea4c8e37554c06c9 40746 pg-gvm_22.6.17.orig.tar.gz
 d4ae2f09e14db77fb06ac13523b3133e9a1a8d7dc9a2cde66c7bae89e0faa1d4 14260 pg-gvm_22.6.17-1.pgdg13+2.debian.tar.xz
Files:
 bf5757cd8fc6c2b4cf4f1cbc9fcf1fb8 40746 pg-gvm_22.6.17.orig.tar.gz
 9dd52db0e41cda4e0ca8d8472317f851 14260 pg-gvm_22.6.17-1.pgdg13+2.debian.tar.xz
