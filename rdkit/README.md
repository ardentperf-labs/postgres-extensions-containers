# RDKit PostgreSQL cartridge

RDKit provides cheminformatics types and functions in PostgreSQL, including SMILES parsing, molecule fingerprints and molecular descriptors. See the [upstream RDKit project](https://github.com/rdkit/rdkit) for toolkit documentation.

The PG18 package is available on Trixie only in this matrix, for amd64 and arm64. Bookworm has RDKit packages for older PostgreSQL majors but no PG18 package.

## Install and use

~~~yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-rdkit
spec:
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie
  instances: 1
  storage:
    size: 1Gi
  postgresql:
    extensions:
    - name: rdkit
      image:
        # renovate: suite=trixie-pgdg depName=postgresql-18-rdkit
        reference: ghcr.io/cnpg-extensions/rdkit:202503.1-18-trixie
      ld_library_path: [system]
---
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: cluster-rdkit-app
spec:
  name: app
  owner: app
  cluster:
    name: cluster-rdkit
  extensions:
  - name: rdkit
    version: '4.7.0'
~~~

Parse a molecular SMILES string, canonicalize it and generate a Morgan fingerprint:

~~~sql
SELECT mol_to_smiles(mol_from_smiles('CCO'))::text = 'CCO'
   AND size(morganbv_fp(mol_from_smiles('CCO'))) > 0;
~~~

No writable storage or runtime shell access is needed for the SQL cartridge functions shown here.

## Package, licensing and updates

PGDG package: 202503.1-5.pgdg13+1; SQL version: 4.7.0. RDKit is BSD-3-Clause; its package copyright and notices for bundled runtime dependencies are included under `/licenses/<package>/`. The image includes no source archives.

Renovate tracks the PGDG package. Rebuild after package or base-image security updates and review the resulting runtime libraries and their notices.
