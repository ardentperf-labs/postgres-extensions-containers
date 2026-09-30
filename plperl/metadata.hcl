# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                       = "plperl"
  sql_name                   = "plperl"
  image_name                 = "plperl"
  licenses                   = ["PostgreSQL", "Artistic-1.0-Perl"]
  shared_preload_libraries   = []
  postgresql_parameters      = {}
  extension_control_path     = []
  dynamic_library_path       = []
  ld_library_path            = ["system"]
  bin_path                   = []
  env                        = { "PERL5LIB" = "$${image_root}/perl/arch:$${image_root}/perl/share:$${image_root}/perl/vendor-arch:$${image_root}/perl/vendor-share" }
  auto_update_os_libs        = false
  required_extensions        = []
  create_extension           = true

  versions = {
    bookworm = {
      "18" = {
        // renovate: suite=bookworm-pgdg depName=postgresql-plperl-18
        package = "18.6-1.pgdg12+2"
        // SQL catalog version is read from the packaged control file; review separately from package updates.
        sql = "1.0"
      }
    }
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-plperl-18
        package = "18.6-1.pgdg13+2"
        // SQL catalog version is read from the packaged control file; review separately from package updates.
        sql = "1.0"
      }
    }
  }
}
