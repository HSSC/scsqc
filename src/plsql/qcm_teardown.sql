----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: script to dismantle QCM from DB
-- Created: Thu Jun 09 2016
----------------------------------------------

spool build_teardown.log
set pagesize 0
SET SERVEROUTPUT ON;

-- drop tables 
drop table "HSSC_ETL"."QCM_SITE" cascade constraints PURGE;
drop table "HSSC_ETL"."QCM_META" cascade constraints PURGE;
drop table "HSSC_ETL"."QCM_CNTRL" cascade constraints PURGE;
drop table "HSSC_ETL"."QCM_CASE" cascade constraints PURGE;

-- drop sequences;
drop sequence "HSSC_ETL"."QCM_BATCH_ID_SEQ";
drop sequence "HSSC_ETL"."QCM_ID_SEQ";
drop sequence "HSSC_ETL"."QCM_LCID_SEQ";

-- drop package
drop package body "HSSC_ETL"."PKG_SCSQC_QCM";
drop package "HSSC_ETL"."PKG_SCSQC_QCM";



-- drop triggers -- will be dropped as part of cascade in tables
--drop trigger "HSSC_ETL"."T_QCM_CASE_BI";
--drop trigger "HSSC_ETL"."T_QCM_CNTRL_BATCH";
--drop trigger "HSSC_ETL"."T_QCM_CNTRL_BI";


-- clean up principals, roles and users
exec sys.xs_principal.delete_principal('sqctest', xs_admin_util.cascade_option);
exec sys.xs_principal.delete_principal('sqc_role', xs_admin_util.cascade_option);
drop role db_sqc cascade;
