----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: Script to create QCM app-user/roles
-- Created: Thu Jun 09 2016
----------------------------------------------


-- create db_sqc role
create role db_sqc;

-- grant connect, create session 
grant connect, create session to db_sqc;

-- grant execute on following packages
grant execute on HSSC_ETL.PKG_SCSQC_QCM to db_sqc;
grant execute on DBMS_LOCK to db_sqc;

-- no delete on tables
grant select, update, insert on HSSC_ETL.QCM_CNTRL to db_sqc;
grant select, update, insert on HSSC_ETL.QCM_META to db_sqc;
grant select, update, insert on HSSC_ETL.QCM_CASE to db_sqc;

-- select only on qcm_site
grant select on HSSC_ETL.QCM_SITE to db_sqc;

-- create application role
exec sys.xs_principal.create_role(name => 'sqc_role', enabled => true);


-- grant db_sqc role to application role
grant db_sqc to sqc_role;

-- create application user
exec  sys.xs_principal.create_user(name => 'sqctest', schema => 'HSSC_ETL');
exec  sys.xs_principal.set_password('sqctest', 'sqc5432');

-- grant user sqctest the application role
exec  sys.xs_principal.grant_roles('sqctest', 'sqc_role');

commit;

