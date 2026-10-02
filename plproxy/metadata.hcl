# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                       = "plproxy"
  sql_name                   = "plproxy"
  image_name                 = "plproxy"
  licenses                   = ["ISC"]
  shared_preload_libraries   = []
  postgresql_parameters      = {}
  extension_control_path     = []
  dynamic_library_path       = []
  ld_library_path            = []
  bin_path                   = []
  env                        = {}
  auto_update_os_libs        = false
  required_extensions        = []
  create_extension           = true

  versions = {
    bookworm = {
      "18" = {
        // renovate: suite=bookworm-pgdg depName=postgresql-18-plproxy
        package = "2.12.0-1.pgdg12+2"
        // SQL catalog version is read from the packaged control file; review separately from package updates.
        sql = "2.12.0"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-plproxy
        package = "2.12.0-1.pgdg13+2"
        // SQL catalog version is read from the packaged control file; review separately from package updates.
        sql = "2.12.0"
      }
    }
  }
}
