# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                     = "londiste"
  sql_name                 = "londiste"
  image_name               = "londiste"
  licenses                 = ["ISC"]
  shared_preload_libraries = []
  postgresql_parameters    = {
  }
  extension_control_path   = []
  dynamic_library_path     = []
  ld_library_path          = []
  bin_path                 = []
  env                      = {}
  auto_update_os_libs      = false
  required_extensions      = ["pgq-node"]
  create_extension         = true
  versions = {
    bookworm = {
      "18" = {
        // renovate: suite=bookworm-pgdg depName=postgresql-18-londiste-sql
        package = "3.8-9.pgdg12+1"
        // renovate: suite=bookworm-pgdg depName=postgresql-18-londiste-sql extractVersion=^(?<version>\d+\.\d+)
        sql     = "3.8"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-londiste-sql
        package = "3.8-9.pgdg13+1"
        // renovate: suite=trixie-pgdg depName=postgresql-18-londiste-sql extractVersion=^(?<version>\d+\.\d+)
        sql     = "3.8"
      }
    }
  }
}
