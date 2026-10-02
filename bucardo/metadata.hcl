# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                     = "bucardo"
  sql_name                 = "bucardo"
  image_name               = "bucardo"
  licenses                 = ["BSD-2-Clause"]
  shared_preload_libraries = []
  postgresql_parameters    = {
  }
  extension_control_path   = []
  dynamic_library_path     = []
  ld_library_path          = []
  bin_path                 = []
  env                      = {}
  auto_update_os_libs      = false
  required_extensions      = ["plperl"]
  create_extension         = false
  versions = {
    bookworm = {
      "18" = {
        // renovate: suite=bookworm-pgdg depName=bucardo
        package = "5.6.0-6.pgdg12+1"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=bucardo
        package = "5.6.0-6.pgdg13+1"
      }
    }
  }
}
