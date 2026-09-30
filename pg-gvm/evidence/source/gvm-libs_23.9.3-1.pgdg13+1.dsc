Format: 3.0 (quilt)
Source: gvm-libs
Binary: libgvm-dev, libgvm-doc, libgvm23
Architecture: any all
Version: 23.9.3-1.pgdg13+1
Maintainer: Debian Security Tools <team+pkg-security@tracker.debian.org>
Uploaders: Sophie Brun <sophie@kali.org>
Homepage: https://www.greenbone.net/
Standards-Version: 4.7.4
Vcs-Browser: https://salsa.debian.org/pkg-security-team/gvm-libs
Vcs-Git: https://salsa.debian.org/pkg-security-team/gvm-libs.git
Build-Depends: dpkg-dev (>= 1.22.5), debhelper-compat (= 13), cmake, libcgreen1-dev [!ppc64el !s390x], libcjson-dev, libcrypt-dev, libcurl4-gnutls-dev, libgcrypt-dev, libglib2.0-dev, libgpgme-dev, libgnutls28-dev, libldap2-dev, libnet1-dev, libpaho-mqtt-dev, libpcap-dev, libssh-dev, libhiredis-dev, libradcli-dev, libxml2-dev, pkgconf, uuid-dev
Build-Depends-Indep: doxygen
Package-List:
 libgvm-dev deb libdevel optional arch=any
 libgvm-doc deb doc optional arch=all
 libgvm23 deb libs optional arch=any
Checksums-Sha1:
 b0204d58205060e51f3fee18f03201cdb631f486 472792 gvm-libs_23.9.3.orig.tar.gz
 31a49e1335340629fad37f3d319325139bd74ff3 16484 gvm-libs_23.9.3-1.pgdg13+1.debian.tar.xz
Checksums-Sha256:
 450f24e8bc96ae3dbb83f4e823a092aa18b7adde1702e36a19b3c4c5e5c20f58 472792 gvm-libs_23.9.3.orig.tar.gz
 3fead2a5b375c5c3742584bcdbc0356ee1fc776883f2772fcb5ffeae8985bd92 16484 gvm-libs_23.9.3-1.pgdg13+1.debian.tar.xz
Files:
 9fe5f9046e46027a50632531ca7d1b9b 472792 gvm-libs_23.9.3.orig.tar.gz
 fd53aa761fab6a5f500a7c438113ef58 16484 gvm-libs_23.9.3-1.pgdg13+1.debian.tar.xz
