# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                       = "periods"
  sql_name                   = "periods"
  image_name                 = "periods"
  licenses                   = ["PostgreSQL"]
  shared_preload_libraries   = []
  postgresql_parameters      = {}
  extension_control_path     = []
  dynamic_library_path       = []
  ld_library_path            = []
  bin_path                   = []
  env                        = {}
  auto_update_os_libs        = false
  required_extensions        = ["base-image:btree_gist"]
  create_extension           = true

  versions = {
    bookworm = {
      "18" = {
        // renovate: suite=bookworm-pgdg depName=postgresql-18-periods
        package = "1.2.3-2.pgdg12+1"
        // renovate: suite=bookworm-pgdg depName=postgresql-18-periods extractVersion=^(?:[0-9]+:)?(?<version>[0-9]+[.][0-9]+)
        sql = "1.2"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-periods
        package = "1.2.3-2.pgdg13+1"
        // renovate: suite=trixie-pgdg depName=postgresql-18-periods extractVersion=^(?:[0-9]+:)?(?<version>[0-9]+[.][0-9]+)
        sql = "1.2"
      }
    }
  }
}
