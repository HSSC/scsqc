----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: DDL for QCM Seq/Trig
-- Created: Thu Jun 09 2016
----------------------------------------------

--------------------------------------------------------
--  DDL for Sequence QCM_BATCH_ID_SEQ
--------------------------------------------------------
CREATE SEQUENCE "HSSC_ETL"."QCM_BATCH_ID_SEQ" 
MINVALUE 1 
MAXVALUE 999999999999999999999999999 
INCREMENT BY 1 
START WITH 101 
CACHE 20 
NOORDER NOCYCLE NOPARTITION ;
--------------------------------------------------------
--  DDL for Sequence QCM_ID_SEQ
--------------------------------------------------------

CREATE SEQUENCE  "HSSC_ETL"."QCM_ID_SEQ"  
MINVALUE 1 
MAXVALUE 999999999999999999999999999 
INCREMENT BY 1 
START WITH 1001 
CACHE 20 
NOORDER NOCYCLE  NOPARTITION ;
--------------------------------------------------------
--  DDL for Sequence QCM_LCID_SEQ
--------------------------------------------------------

CREATE SEQUENCE  "HSSC_ETL"."QCM_LCID_SEQ"  
MINVALUE 1 
MAXVALUE 999999999999999999999999999 
INCREMENT BY 1 
START WITH 11 
CACHE 20 NOORDER NOCYCLE  NOPARTITION ;


--- trigger - increment qcm_id before insert into QCM_CNTRL
create or replace TRIGGER HSSC_ETL.T_QCM_CNTRL_BI
BEFORE INSERT
ON HSSC_ETL.QCM_CNTRL
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
begin
 if :new.qcm_id is null then
  select HSSC_ETL.QCM_ID_SEQ.nextval into :new.qcm_id from dual;
 end if;
end T_QCM_CNTRL_BI;
/

--- trigger - increment local_case_id before insert into QCM_CASE
create or replace TRIGGER HSSC_ETL.T_QCM_CASE_BI
BEFORE INSERT
ON HSSC_ETL.QCM_CASE
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
begin
 if :new.local_case_id is null then
  select HSSC_ETL.QCM_LCID_SEQ.nextval into :new.local_case_id from dual;
 end if;
end T_QCM_CASE_BI;
/
