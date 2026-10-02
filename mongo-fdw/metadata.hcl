# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                     = "mongo-fdw"
  sql_name                 = "mongo_fdw"
  image_name               = "mongo-fdw"
  licenses                 = ["PostgreSQL", "LGPL-3.0-only", "Apache-2.0"]
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
        // renovate: suite=trixie-pgdg depName=postgresql-18-mongo-fdw
        package = "5.5.3-1.pgdg13+1"
        // The PGDG package version and extension catalog version are independent.
        sql     = "1.1"
      }
    }
  }
}
