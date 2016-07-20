----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: load tables script
-- Created: Thu Jun 09 2016
----------------------------------------------

spool build_output_01.log
set pagesize 0
SET SERVEROUTPUT ON;


prompt 'QCM01: creating table qcm_site';
@qcm_site_ddl.sql
/

prompt "QCM01: loading qcm_site data";
@qcm_site_data.sql
/

prompt "QCM01: creating table qcm_meta";
@qcm_meta_ddl.sql
/

prompt "QCM01: creating table qcm_cntrl"
/

@qcm_cntrl_ddl.sql
/

prompt "QCM01: creating table qcm_case";

@qcm_case_ddl.sql
/

prompt "QCM01: creating table qcm_proc_codes";
@qcm_proc_codes_ddl.sql
/

prompt "QCM01: inserting data into qcm_proc_codes";
@qcm_proc_codes_data.sql
/

prompt "QCM01: creating table qcm_map_county";
@qcm_map_county_ddl.sql
/

prompt "QCM01: inserting data into qcm_map_county";
@qcm_map_county_data.sql
/

prompt "--> done "
