/**********
 Meta data to store transaction (=batch) 
 level details of payload handoff and response
**********/

CREATE TABLE QCM_META
   (

    -- Batch details -----------------------------------------------

    -- Batch ID 
    BATCH_ID NUMBER NOT NULL ENABLE,

    -- SCSQC_QCM_EXTRACT
    BATCH_TYPE VARCHAR2 (60 BYTE) NOT NULL ENABLE,
    
    -- Batch Status
    BATCH_STATUS VARCHAR2(1 BYTE) NOT NULL ENABLE,


    -- Payload details -----------------------------------------------

    -- Payload file name
    QCM_DAT_FNAME VARCHAR2(60 BYTE) NOT NULL ENABLE,

    -- Payload last modified time
    QCM_DAT_MOD DATE NOT NULL ENABLE,

    -- Payload number of records 
    QCM_DAT_NREC NUMBER NOT NULL ENABLE,

    -- Payload file size
    QCM_DAT_SIZE FLOAT NOT NULL,

    -- Payload transfer rate
    QCM_DAT_RATE FLOAT NOT NULL,

    -- Response details -----------------------------------------------

    -- Response file creation time
    QCM_RES_ARRIVAL DATE NOT NULL ENABLE,
    
    -- Response file last modified time
    QCM_RES_MOD DATE NOT NULL ENABLE,
    
    -- Response file processing completion time
    QCM_RES_COMPL DATE NOT NULL ENABLE,
    
    -- Response file name
    QCM_RES_FNAME VARCHAR2(60 BYTE) NOT NULL ENABLE,
    
    -- Transaction start time
    TX_START DATE,
    
    -- Transacion end time
    TX_COMPL DATE,
    
    CONSTRAINT pkc_batch_id PRIMARY KEY (BATCH_ID)

   )
   SEGMENT CREATION IMMEDIATE
   PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
   NOCOMPRESS LOGGING
   STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
   PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
   BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
   TABLESPACE HSSC_ETL
;



    COMMENT ON COLUMN QCM_META.BATCH_ID 
    IS 'Batch ID';
    
    COMMENT ON COLUMN QCM_META.BATCH_STATUS 
    IS 'Batch Status';
 
    COMMENT ON COLUMN QCM_META.BATCH_TYPE 
    IS 'SCSQC_QCM_EXTRACT';
    
    COMMENT ON COLUMN QCM_META.QCM_DAT_FNAME
    IS 'Payload file name';

    COMMENT ON COLUMN QCM_META.QCM_DAT_MOD 
    IS 'Payload last modified time';

    COMMENT ON COLUMN QCM_META.QCM_DAT_NREC 
    IS 'Payload number of records';

    COMMENT ON COLUMN QCM_META.QCM_DAT_SIZE 
    IS 'Payload file size';

    COMMENT ON COLUMN QCM_META.QCM_DAT_RATE 
    IS 'Payload transfer rate';

    COMMENT ON COLUMN QCM_META.QCM_RES_ARRIVAL 
    IS 'Response file creation time';
    
    COMMENT ON COLUMN QCM_META.QCM_RES_MOD 
    IS 'Response file last modified time';
    
    COMMENT ON COLUMN QCM_META.QCM_RES_COMPL 
    IS 'Response file processing completion time';
    
    COMMENT ON COLUMN QCM_META.QCM_RES_FNAME 
    IS 'Response file name';
    
    COMMENT ON COLUMN QCM_META.TX_START 
    IS 'Transaction start time';
      
    COMMENT ON COLUMN QCM_META.TX_COMPL 
    IS 'Transacion end time';

----------------------------------------------------------

/**********
 Table to store QCM case details ( presumably per procedure)
 and link it to unique CDW columns in multiple tables.
**********/

CREATE TABLE QCM_CASE
    ( 
  
  -- QCM Case Number 
  RES_CASE_ID VARCHAR2(50 BYTE) NOT NULL ENABLE,

  -- Local Case Number
  LOCAL_CASE_ID VARCHAR2(200 BYTE) NOT NULL ENABLE,
  
  -- Visit ID (CDW.VISIT.VISIT_ID)
  VISIT_ID NUMBER(22,0) NOT NULL ENABLE, 

  -- Encounter Act ID
  HTB_ENC_ACT_ID NUMBER(22,0),

  -- Patient Medical Record Number (CDW.PATIENT.MRN)
  MRN VARCHAR2(50 BYTE),
  
  -- Procedure ID (CDW.PROCEDURE.PROCEDURE_ID)
  PROCEDURE_ID NUMBER(22,0) NOT NULL ENABLE,
  
  -- Site ROOT (CDW.DATASOURCE.DATASOURCE_ROOT)
  DATASOURCE_ROOT VARCHAR2(500 BYTE) NOT NULL ENABLE,
  
    -- Primary Key
  CONSTRAINT pkc_local_case_id PRIMARY KEY (LOCAL_CASE_ID)
  

   ) SEGMENT CREATION IMMEDIATE 
     PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
     NOCOMPRESS LOGGING
     STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
     PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
     BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
     TABLESPACE HSSC_ETL  
;      


  COMMENT ON COLUMN QCM_CASE.LOCAL_CASE_ID
  IS 'Local Case ID ';

  COMMENT ON COLUMN QCM_CASE.RES_CASE_ID
  IS 'QCM Case ID ';
  
  COMMENT ON COLUMN QCM_CASE.DATASOURCE_ROOT 
  IS 'Site ROOT (CDW.DATASOURCE.DATASOURCE_ROOT)';
  
  COMMENT ON COLUMN QCM_CASE.VISIT_ID 
  IS 'Visit ID (=VISIT.VISIT_ID)';
  
  COMMENT ON COLUMN QCM_CASE.MRN 
  IS 'Patient Medical Record Number (=PATIENT.MRN)';

  COMMENT ON COLUMN QCM_CASE.HTB_ENC_ACT_ID 
  IS 'Encounter Act ID (=VISIT.HTB_ENC_ACT_ID)';
  
  COMMENT ON COLUMN QCM_CASE.PROCEDURE_ID 
  IS 'Procedure ID (=PROCEDURE.PROCEDURE_ID)';
-------------------------------------------------------
  
/**********
 Control table stores QCM response (presumably per procedure)
 and links to meta-data and case 
**********/

CREATE TABLE QCM_CNTRL
   (    

  -- QCM Unique ID for each record
  QCM_ID NUMBER(22, 0) NOT NULL,
  
  -- Batch ID 
  BATCH_ID NUMBER NOT NULL ENABLE, 

  -- Local Case Number 
  LOCAL_CASE_ID VARCHAR2(200 BYTE) NOT NULL ENABLE,
  
  -- Status of a single QCM_CNTRL record
  REC_STATUS VARCHAR2 (30 BYTE) NOT NULL ENABLE,
  
  -- Response Status (Created, Failure, Success)
  RES_STATUS VARCHAR2(30 BYTE),
  
  --Response SITE ()
  RES_SITE VARCHAR2(30 BYTE),
  
  -- Response Type (Information, Validation, Load To Server, Schema Validation)
  RES_TYPE VARCHAR(30 BYTE),
  
  -- Patient Medical Record Number (CDW.PATIENT.MRN)
  RES_MRN VARCHAR2(50 BYTE),

  -- QCM Case Number 
  RES_CASE_ID VARCHAR2(50 BYTE) NOT NULL ENABLE,
   
  -- Primary Key
  CONSTRAINT pkc_qcm_id PRIMARY KEY (QCM_ID),

  -- FK Constraint
  CONSTRAINT fk_qcm_trans_batch_id FOREIGN KEY (BATCH_ID) REFERENCES QCM_META (BATCH_ID),
  
      -- FK Constraint
  CONSTRAINT fk_qcm_local_case_id FOREIGN KEY (LOCAL_CASE_ID) REFERENCES QCM_CASE (LOCAL_CASE_ID)

  
   ) SEGMENT CREATION IMMEDIATE 
     PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
     NOCOMPRESS LOGGING
     STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
     PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
     BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
     TABLESPACE HSSC_ETL  
;

  COMMENT ON COLUMN QCM_CNTRL.QCM_ID 
  IS 'QCM Unique ID';

  COMMENT ON COLUMN QCM_CNTRL.LOCAL_CASE_ID
  IS 'Local Case ID ';
  
  COMMENT ON COLUMN QCM_CNTRL.BATCH_ID
  IS 'Batch ID'; 
  
  COMMENT ON COLUMN QCM_CNTRL.REC_STATUS
  IS 'Status of a single QCM_CNTRL record';
    
  COMMENT ON COLUMN QCM_CNTRL.RES_STATUS 
  IS 'QCM Response Status (Created, Failure, Success)';
  
  COMMENT ON COLUMN QCM_CNTRL.RES_TYPE 
  IS 'QCM Response Type (Information, Validation, Load To Server, Schema Validation)';

  COMMENT ON COLUMN QCM_CNTRL.RES_MRN 
  IS 'QCM Patient Medical Record Number (=PATIENT.MRN)';
  
  COMMENT ON COLUMN QCM_CNTRL.RES_CASE_ID 
  IS 'QCM Case Number ';
  
  COMMENT ON COLUMN QCM_CNTRL.RES_SITE 
  IS 'QCM Site ID ';

  
/**********
 Static QCM Site <--> CDW Site ROOT lookup table
 **********/

CREATE TABLE QCM_SITE
   ( 
   
  RES_SITE VARCHAR2(30 BYTE),
  
  DATASOURCE_ROOT VARCHAR2(500 BYTE) NOT NULL ENABLE,
  
  -- Primary Key
  CONSTRAINT pkc_res_site PRIMARY KEY (RES_SITE)
  
  
   ) SEGMENT CREATION IMMEDIATE 
     PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
     NOCOMPRESS LOGGING
     STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
     PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
     BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
     TABLESPACE HSSC_ETL  
;

-- Scope of data exchange (limited to the following sites)
-- https://docs.google.com/document/d/1qcuF7Az1Lm2c4cgFH-OVaG0aFl5b3OhjDoyznNRFQNk/edit#heading=h.ua0af42g8rxl

INSERT INTO QCM_SITE (DATASOURCE_ROOT, RES_SITE) VALUES
( '2.16.840.1.113883.3.2489.2.1.2.1.3.1.2.4', '1004'); 

INSERT INTO QCM_SITE (DATASOURCE_ROOT, RES_SITE) VALUES
(  '2.16.840.1.113883.3.2489.2.3.4.1.2.4.3', '1007');

INSERT INTO QCM_SITE (DATASOURCE_ROOT, RES_SITE) VALUES
('2.16.840.1.113883.3.2489.2.4.4.1.2.4.2', '1002'
  );


/*
RES_SITE  DATASOURCE_ROOT -- of Encounter
1004      2.16.840.1.113883.3.2489.2.1.2.1.3.1.2.4  -- MUSC 
1007      2.16.840.1.113883.3.2489.2.3.4.1.2.4.3 -- PH Easley
1002      2.16.840.1.113883.3.2489.2.4.4.1.2.4.2 -- SRHS (Medical Center)
*/
