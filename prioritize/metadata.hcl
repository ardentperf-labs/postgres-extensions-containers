# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                       = "prioritize"
  sql_name                   = "prioritize"
  image_name                 = "prioritize"
  licenses                   = ["PostgreSQL"]
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
        // renovate: suite=bookworm-pgdg depName=postgresql-18-prioritize
        package = "1.0.4-13.pgdg12+1"
        // SQL catalog version is read from the packaged control file; review separately from package updates.
        sql = "1.0"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-prioritize
        package = "1.0.4-13.pgdg13+1"
        // SQL catalog version is read from the packaged control file; review separately from package updates.
        sql = "1.0"
      }
    }
  }
}
