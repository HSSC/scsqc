----------------------------------------------
-- Project: SCSQC
-- Author: Evan Phelps 
-- Purpose: ICD9/10/CPT4 Procedure Codes
-- Created: Thu Jul 05 2016
----------------------------------------------


--------------------------------------------------------
--  DDL for Table QCM_PROC_CODES
--------------------------------------------------------

  CREATE TABLE "HSSC_ETL"."QCM_PROC_CODES" 
   (	"SQC_PROC" VARCHAR2(256 BYTE), 
	"CODE_SYS" VARCHAR2(16 BYTE), 
	"CODE_VAL" VARCHAR2(12 BYTE), 
	"CODE_DESC" VARCHAR2(1024 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HSSC_ETL" ;
--------------------------------------------------------
--  DDL for Index PKC_CODE_SYS_VAL
--------------------------------------------------------

  CREATE UNIQUE INDEX "HSSC_ETL"."PKC_CODE_SYS_VAL" ON "HSSC_ETL"."QCM_PROC_CODES" ("CODE_SYS", "CODE_VAL") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HSSC_ETL" ;
--------------------------------------------------------
--  Constraints for Table QCM_PROC_CODES
--------------------------------------------------------

  ALTER TABLE "HSSC_ETL"."QCM_PROC_CODES" ADD CONSTRAINT "PKC_CODE_SYS_VAL" PRIMARY KEY ("CODE_SYS", "CODE_VAL")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HSSC_ETL"  ENABLE;

