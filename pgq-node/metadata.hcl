# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                     = "pgq-node"
  sql_name                 = "pgq_node"
  image_name               = "pgq-node"
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
  required_extensions      = ["pgq"]
  create_extension         = true
  versions = {
    bookworm = {
      "18" = {
        // renovate: suite=bookworm-pgdg depName=postgresql-18-pgq-node
        package = "3.5-9.pgdg12+1"
        // renovate: suite=bookworm-pgdg depName=postgresql-18-pgq-node extractVersion=^(?<version>\d+\.\d+)
        sql     = "3.5"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-pgq-node
        package = "3.5-9.pgdg13+1"
        // renovate: suite=trixie-pgdg depName=postgresql-18-pgq-node extractVersion=^(?<version>\d+\.\d+)
        sql     = "3.5"
      }
    }
  }
}
