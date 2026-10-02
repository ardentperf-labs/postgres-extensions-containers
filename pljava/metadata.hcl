# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                     = "pljava"
  sql_name                 = "pljava"
  image_name               = "pljava"
  licenses                 = ["BSD-3-Clause"]
  shared_preload_libraries = []
  postgresql_parameters = {
    "pljava.libjvm_location" = "/extensions/pljava/jvm/lib/server/libjvm.so"
    "pljava.module_path"     = "/extensions/pljava/share/pljava/pljava-1.6.10.jar:/extensions/pljava/share/pljava/pljava-api-1.6.10.jar"
    "pljava.vmoptions"       = "-Djava.security.manager=allow -Djava.io.tmpdir=/controller/tmp"
    "pljava.policy_urls"     = "\"file:/extensions/pljava/share/pljava.policy\""
  }
  extension_control_path = []
  dynamic_library_path   = []
  ld_library_path        = ["jvm/lib/server", "jvm/lib", "system"]
  bin_path               = []
  env                    = {}
  auto_update_os_libs    = false
  required_extensions    = []
  create_extension       = true

  versions = {
    bookworm = {
      "18" = {
        // renovate: suite=bookworm-pgdg depName=postgresql-18-pljava
        package = "1.6.10-1.pgdg12+1"
        // renovate: suite=bookworm-pgdg depName=postgresql-18-pljava extractVersion=^(?<version>\d+\.\d+\.\d+)
        sql     = "1.6.10"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-pljava
        package = "1.6.10-1.pgdg13+1"
        // renovate: suite=trixie-pgdg depName=postgresql-18-pljava extractVersion=^(?<version>\d+\.\d+\.\d+)
        sql     = "1.6.10"
      }
    }
  }
}
