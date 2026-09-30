# Package and build evidence for ogr_fdw

## PGDG package verification

PGDG publishes PG18 packages on Bookworm and Trixie. Disposable PG18/amd64 CNPG minimal containers were used to inspect APT origin and candidate, package metadata and dependencies, installed payload and control/SQL files for each suite. The 2026-09-29 PGDG indexes show amd64 and arm64 package entries for both suites.

| Debian suite | PG18 package version | SQL catalog version | Architecture evidence |
|---|---|---|---|
| bookworm | `postgresql-18-ogr-fdw` `1.1.9-1.pgdg12+1` | `ogr_fdw` `1.1` | PGDG amd64 and arm64 indexes |
| trixie | `postgresql-18-ogr-fdw` `1.1.9-1.pgdg13+1` | `ogr_fdw` `1.1` | PGDG amd64 and arm64 indexes |

## Runtime closure, GIS data, and source accounting

The Trixie/amd64 scratch payload contains `ogr_fdw.so`, its control/SQL files, the resolved GDAL library closure, and the matching `/usr/share/gdal` and `/usr/share/proj` data trees. The image sets `GDAL_DATA` and `PROJ_DATA` to those bundled directories. Per-build exact package versions and architectures are recorded in `/licenses/runtime-packages.txt`; unchanged CNPG-base linkages are in `/licenses/base-linkages.txt`; package copyright and Debian common-license texts are under `/licenses`.

The extension license is MIT. Copyleft-linked runtime components include exact corresponding Debian source archives under `/source`; `/licenses/source-packages.txt` records the suite-specific source package versions for each built image. The Bookworm closure includes `libde265-0` (`libde265` source `1.0.11-1+deb12u3`), `libsuperlu5` (`superlu` source `5.3.0+dfsg1-2`), `libtirpc3` (`libtirpc` source `1.3.3+ds-1`), and `libx265-199` (`x265` source `3.5-2`); all four exact source archives are bundled and included in the Bookworm source manifest because their Debian copyright files trigger the copyleft source-accounting check. The Trixie source manifest lists:

```text
armadillo 1:14.2.3+dfsg-1
cfitsio 4.6.2-2
freetype 2.13.3+dfsg-1+deb13u1
freexl 2.0.0-1
fyba 4.1.1-11
gcc-14 14.2.0-19
gdal 3.13.2+dfsg-1.pgdg13+1
geos 3.14.1-2.pgdg13+1
gpgme1.0 1.24.2-3
hdf5 1.14.5+repack-3
jbigkit 2.1-6.1
lcms2 2.16-2+deb13u2
libgeotiff 1.7.4-1
libhdf4 4.3.0-1
libheif 1.23.4-1~deb13u1
libkml 1.3.0-12
librttopo 1.1.0-4
libtool 2.5.4-4
mariadb 1:11.8.6-0+deb13u1
muparser 2.3.4-1
ngtcp2 1.11.0-1+deb13u1
poppler 25.03.0-5+deb13u4
proj 9.8.1-1.pgdg13+1
qhull 2020.2-6
rtmpdump 2.4+20151223.gitfa8646d.1-2
spatialite 5.1.0-3
unixodbc 2.3.12-2+deb13u1
```

These sources are downloaded from the configured signed PGDG/Debian source indexes during the image build. Permissive dependencies retain their package copyright and applicable patent notices; copied GCC runtime libraries are accompanied by exact GCC source. Renovate tracks both suite-specific PGDG packages and rebuilds regenerate the runtime/source manifests and bundled data.

## Validation status

- PGDG installation, payload and SQL controls: inspected on disposable Bookworm/amd64 and Trixie/amd64 PG18 CNPG minimal images. Both suites are advertised; architecture availability was checked in PGDG indexes.
- Trixie/amd64 scratch image built. A fresh PG18/Trixie minimal payload mount had a clean `ldd` closure, loaded `ogr_fdw`, found the staged GDAL/PROJ data, and read feature id `42` and label `survey marker` from a GeoJSON fixture through an application-role foreign table.
- The same local GeoJSON query succeeded against the installed package on Bookworm/amd64. The final Bookworm scratch images built on amd64 and arm64, and the CNPG mounted-payload functional test passed on amd64.
- Both-suite Chainsaw execution, actual README deployment, final repository checks and the complete architecture build matrix passed. Detailed records are linked below.

## Integrated validation

`task e2e:test:full TARGET=ogr-fdw DISTRO=<suite>` passed for every
advertised suite: [trixie](evidence/runtime/trixie-amd64.json), [bookworm](evidence/runtime/bookworm-amd64.json). These runs built the scratch images for
**amd64 and arm64** and ran the generic and functional Chainsaw suites on
**amd64** CNPG clusters. An arm64 runtime environment was unavailable.

The [README deployment](evidence/runtime/readme-trixie-amd64.json) also passed
on Trixie/amd64. The JSON records preserve exact commands, immutable image and
architecture digests, and tested source/README hashes. Final repository-wide
checks and the shared-tooling regressions are recorded in the
[batch evidence](../docs/approved-batch/README.md).
