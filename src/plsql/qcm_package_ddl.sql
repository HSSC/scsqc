> ----------------------------------------------
> -- Project: SCSQC
> -- Author: Venkat Kaushik, Evan Phelps
> -- Purpose: Package skeleton for QCM Ex/Tr
> -- Created: Thu Jun 09 2016
> ----------------------------------------------

--------------------------------------------------------
--  DDL for Package PKG_SCSQC_QCM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HSSC_ETL"."PKG_SCSQC_QCM" 
AS
  -- Mapping Record from CDW -> QCM
TYPE QCMRecordType
IS
  RECORD
  (
    -- Mapping QCM types to CDW types
    -- Note 1: map one-to-one for primitive types and mark with "P"
    -- Note 2: Indicate if it's a complex type requiring transformation
    --         and/or encapsulation with the letter "T"
    -- You may need to come up with other classifiers
    Site HSSC_ETL.QCM_SITE.RES_SITE%TYPE,              -- P
    MRN CDW.PATIENT_ID_MAP.MPI_LID%TYPE,               -- P
    DOB CDW.PATIENT.BIRTH_DATE%TYPE,                   -- P
    OP_Date CDW."PROCEDURE".PROC_END_DATE%TYPE        -- P
    --IDX NUMBER
  );

  -- Mapping Table from CDW-> QCM
TYPE QCMTableType
IS
  TABLE OF QCMRecordType;

FUNCTION GET_CONSTANT(i_const IN VARCHAR)  
RETURN VARCHAR2 DETERMINISTIC;

  -- Procedure to extract data into Mapping Table
  PROCEDURE ex_tr_qcm(
      p_trans_t0 qcm_meta.tx_start%type,
      p_site_id NUMBER DEFAULT NULL,
      p_batch_id OUT NUMBER,
      m_cur   IN OUT  SYS_REFCURSOR,
      p_max_days NUMBER DEFAULT 120
      );
      
    /* Some state variables */
  C_STAT_QCM_PREP      CONSTANT VARCHAR2(1) := 'P';
  C_STAT_QCM_STAGE     CONSTANT VARCHAR2(1) := 'S';
  C_STAT_QCM_CASE      CONSTANT VARCHAR2(1) := 'A';
  C_STAT_QCM_CNTRL     CONSTANT VARCHAR2(1) := 'N';
  C_STAT_QCM_FTP       CONSTANT VARCHAR2(1) := 'F';
  C_STAT_QCM_RES       CONSTANT VARCHAR2(1) := 'R';
  C_STAT_QCM_ERROR     CONSTANT VARCHAR2(1) := 'E';
  C_STAT_QCM_SUCCESS   CONSTANT VARCHAR2(1) := 'C';

END PKG_SCSQC_QCM;

/
