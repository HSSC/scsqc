----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: load package and app users/roles
-- Created: Thu Jun 09 2016
----------------------------------------------

spool build_output_03.log
set pagesize 0
SET SERVEROUTPUT ON;

prompt "QCM03: creating package";
@qcm_package_ddl.sql
/

prompt "QCM03: creating package body";
@qcm_package_body_ddl.sql
/

prompt "QCM03: creating users/roles";
@qcm_user_roles.sql
/


