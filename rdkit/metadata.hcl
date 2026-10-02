# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                     = "rdkit"
  sql_name                 = "rdkit"
  image_name               = "rdkit"
  licenses                 = ["BSD-3-Clause"]
  shared_preload_libraries = []
  postgresql_parameters    = {}
  extension_control_path   = []
  dynamic_library_path     = []
  ld_library_path          = ["system"]
  bin_path                 = []
  env                      = {}
  auto_update_os_libs      = false
  required_extensions      = []
  create_extension         = true

  versions = {
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-rdkit
        package = "202503.1-5.pgdg13+1"
        // The package version reflects the 2025 release; the SQL extension version is 4.7.0.
        sql     = "4.7.0"
      }
    }
  }
}
