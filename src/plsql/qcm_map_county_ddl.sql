----------------------------------------------
-- Project: SCSQC
-- Author: Evan Phelps 
-- Purpose: DDL for QCM_MAP_COUNTY table
-- Created: Thu Jun 13 2016
----------------------------------------------

--------------------------------------------------------
--  DDL for Table QCM_MAP_COUNTY
--------------------------------------------------------

  CREATE TABLE "HSSC_ETL"."QCM_MAP_COUNTY" 
   (    "FIPS" CHAR(6 BYTE), 
    "STATE" CHAR(2 BYTE), 
    "COUNTY" VARCHAR2(64 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HSSC_ETL" ;
--------------------------------------------------------
--  Constraints for Table QCM_MAP_COUNTY
--------------------------------------------------------

  ALTER TABLE "HSSC_ETL"."QCM_MAP_COUNTY" MODIFY ("COUNTY" NOT NULL ENABLE);
  ALTER TABLE "HSSC_ETL"."QCM_MAP_COUNTY" MODIFY ("STATE" NOT NULL ENABLE);
  ALTER TABLE "HSSC_ETL"."QCM_MAP_COUNTY" MODIFY ("FIPS" NOT NULL ENABLE);

