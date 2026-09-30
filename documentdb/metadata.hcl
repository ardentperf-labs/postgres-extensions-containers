# SPDX-FileCopyrightText: Copyright © contributors to CNPG Extensions.
# SPDX-License-Identifier: Apache-2.0
metadata = {
  name                     = "documentdb"
  sql_name                 = "documentdb"
  image_name               = "documentdb"
  licenses                 = ["MIT", "Apache-2.0", "PostgreSQL", "AGPL-3.0-or-later"]
  shared_preload_libraries = ["pg_documentdb", "pg_documentdb_core", "pg_cron", "pg_documentdb_extended_rum"]
  postgresql_parameters    = {
    "cron.database_name" = "app"
    # DocumentDB uses libpq for some local, out-of-transaction work. Route
    # those self-connections through CNPG's peer-authenticated Unix socket.
    "documentdb.localhost_connection_string" = "host=/controller/run"
  }
  extension_control_path   = []
  dynamic_library_path     = []
  ld_library_path          = ["system"]
  bin_path                 = []
  env                      = {}
  auto_update_os_libs      = false
  required_extensions      = [
    "image-sql:documentdb_core",
    "pg-cron",
    "base-image:tsm_system_rows",
    "catalog:pgvector:vector",
    "postgis",
    "rum",
  ]
  create_extension         = true

  versions = {
    trixie = {
      "18" = {
        // renovate: suite=trixie-pgdg depName=postgresql-18-documentdb
        package = "1.0~RC1-1.pgdg13+1"
        // The PGDG package release uses 1.0~RC1; the SQL control uses 1.0-0.
        sql     = "1.0-0"
      }
    }
  }
}
