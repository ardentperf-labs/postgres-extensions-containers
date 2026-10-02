CREATE EXTENSION tds_fdw;
CREATE SERVER mssql_svr
  FOREIGN DATA WRAPPER tds_fdw
  OPTIONS (servername 'localhost', port '1433', database 'test', tds_version '7.2', msg_handler 'blackhole');
-- newest supported TDS version on xenial is 7.2
