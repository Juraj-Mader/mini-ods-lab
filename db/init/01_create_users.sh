#!/bin/bash
# Creates the two lab schemas in the FREEPDB1 pluggable database.
#   SRC_APP - simulated source application (order system)
#   ODS_APP - operational data store that loads data from SRC_APP
# Passwords come from .env through docker-compose.yml.

sqlplus -s / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE USER src_app IDENTIFIED BY "${SRC_APP_PASSWORD}"
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE JOB TO src_app;

CREATE USER ods_app IDENTIFIED BY "${ODS_APP_PASSWORD}"
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE JOB TO ods_app;

EXIT
EOF
