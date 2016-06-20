/*************************** PACKAGE STARTS HERE ***********************/


/* Package Definition

   Package Name: PKG_SCSQC_QCM
   Contents:

   Mapping Record 
   1. Define a custom record type to hold QCM data
      This record represents the serialized version
      required for QCM payload. It could be a nested
      data structure (if necessary)
      Custom Data Type: QCMRecordType

   Mapping Table
   2. Define a custom table to hold extracted QCMRecordType
      data. This table will contain data for all sites.
      Custom Table Type: QCMTableType

   Extract Method
   3. Procedure to extract the QCM payload and populate
      QCMTableType table as a bulk insert operation.
      Procedure Name: EX_TR_QCM
      Input Parameters:
      Output: 
***********************************************************
*/

CREATE SEQUENCE  QCM_BATCH_ID_SEQ  
MINVALUE 1 
MAXVALUE 999999999999999999999999999 
INCREMENT BY 1 START WITH 21 CACHE 20 
NOORDER  NOCYCLE  NOPARTITION
;
/


CREATE OR REPLACE PACKAGE PKG_SCSQC_QCM
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
    OP_Date CDW."PROCEDURE".PROC_END_DATE%TYPE         -- P 
  );

  -- Mapping Table from CDW-> QCM
TYPE QCMTableType
IS
  TABLE OF QCMRecordType;

  -- Procedure to extract data into Mapping Table
  PROCEDURE ex_tr_qcm(
      p_trans_t0 qcm_meta.tx_start%type DEFAULT NULL,
      p_max_trans_period NUMBER DEFAULT NULL,
      m_cur IN OUT SYS_REFCURSOR
      );
      
END PKG_SCSQC_QCM;
/


CREATE OR REPLACE PACKAGE BODY PKG_SCSQC_QCM
AS

  PKG infolog.package_name%TYPE := 'PKG_SCSQC_QCM';
  /* Absent an explicit date being provided as a parameter,
  an exception will be thrown if the transaction start
  time t0 < sysdate-IMPLICIT_MAX_DAYS */
  IMPLICIT_MAX_DAYS NUMBER := 90;

  /* User-defined error numbers must be in range [-20999,-20000]. */
  ERRNUM_INCREMENTAL_TOO_BIG NUMBER         := -20999;
  ERRMSG_INCREMENTAL_TOO_BIG VARCHAR2(2048) :=
  'Incremental period is greater than specified maximum.';

  /* If previous batch did not complete, raise exception. */
  ERRNUM_LAST_INCOMPLETE NUMBER         := -20998;
  ERRMSG_LAST_INCOMPLETE VARCHAR2(2048) := 'The last batch did not complete';

  /* If an unexpected state is detected */
  ERRNUM_INCONSISTENCY NUMBER         := -20997;
  ERRMSG_INCONSISTENCY VARCHAR2(2048) := 'Unexpected state.';

  /* Some state variables */
  C_STAT_MPI_PREP      CONSTANT VARCHAR2(1) := 'P';
  C_STAT_MPI_STAGE     CONSTANT VARCHAR2(1) := 'S';
  C_STAT_MPI_MERGE     CONSTANT VARCHAR2(1) := 'M';
  C_STAT_MPI_MAPLIDS   CONSTANT VARCHAR2(1) := 'L';
  C_STAT_MPI_RECONCILE CONSTANT VARCHAR2(1) := 'R';
  C_STAT_MPI_ERROR     CONSTANT VARCHAR2(1) := 'E';
  C_STAT_MPI_SUCCESS   CONSTANT VARCHAR2(1) := 'C';

  PROCEDURE ex_tr_qcm(
      p_trans_t0 qcm_meta.tx_start%type DEFAULT NULL,
      p_max_trans_period NUMBER DEFAULT NULL,
      --m_qcmextresults OUT QCMTableType 
      m_cur   IN OUT  SYS_REFCURSOR
      )
  IS
    PRCDR infolog.procedure_name%TYPE := 'ex_tr_qcm';


    m_batch_id         NUMBER := qcm_batch_id_seq.NEXTVAL;
    m_batch_stat_last  CHAR(1);
    m_time_start       DATE := SYSDATE;
    m_trans_t0         DATE := p_trans_t0;
    m_trans_t1         DATE := m_time_start;
    m_batch_id_last    NUMBER;
    m_max_trans_period NUMBER             := p_max_trans_period;
    m_pkg              VARCHAR2(100 BYTE) := 'PKG_SCSQC_QCM';
    m_prc              VARCHAR2(100 BYTE) := 'EX_TR_QCM';
    
    --m_qcmextresults    QCMTableType;
    
    
    

  BEGIN
    /*  
    IF m_trans_t0 IS NULL THEN
    RAISE_APPLICATION_ERROR(ERRNUM_INCONSISTENCY,
    ERRMSG_INCONSISTENCY
    || ' TRANS_TIME_LAST is missing from last batch (#'
    || m_batch_id_last || ').');
    END IF;
    IF sysdate-m_trans_t0 > m_max_trans_period THEN
    RAISE_APPLICATION_ERROR(ERRNUM_INCREMENTAL_TOO_BIG,
    ERRMSG_INCREMENTAL_TOO_BIG
    || ' Transaction period is '
    || round(sysdate-m_trans_t0)
    || ' days; max is '
    || m_max_trans_period || ' days.');
    END IF;
    */
    
    OPEN m_cur FOR
    
       -- CDW extraction logic
       
      SELECT
        /*+ PARALLEL 4 */

        -- encounter (CDW.VISIT)
        --v.visit_id,
        --v.HTB_ENC_ID_ROOT,
        -- site details (HSSC_ETL.QCM_SITE)
        
        qs.res_site,
        -- procedure ( CDW.PROCEDURE)
        --px.procedure_id,
        --px.datasource_id,
        -- MRN (CDW.PATIENT_ID_MAP)
        
        pim.mpi_lid,
        -- DOB (CDW.PATIENT)
        
        p.birth_date,
        --p.patient_id,
        
        px.proc_end_date
        
      FROM
        hssc_etl.qcm_site qs
        -- visit htb_enc_id_root = qcm_site datasource_root
      INNER JOIN cdw.visit v
      ON
        (
          v.htb_enc_id_root = qs.datasource_root
        )
        -- procedure(visit_id) = visit(visit_id)
      INNER JOIN cdw.procedure px
      ON
        (
          px.visit_id = v.visit_id
        )
        -- patient(patient_id) = visit(patient_id)
      INNER JOIN cdw.patient p
      ON
        (
          p.patient_id = v.patient_id
        )
        -- patient_id_map(patient_id) = visit(patient_id)
      INNER JOIN cdw.patient_id_map pim
      ON
        (
          pim.patient_id = v.patient_id
        )
        -- ;
        -- extra filters
      WHERE
        -- configurable procedure start date > T - P
        px.proc_end_date > (sysdate - 90)
      ;
      
      --AND
        -- restrict to a given site
        --qs.res_site = '1007';
    
    
  END ex_tr_qcm;
  
END PKG_SCSQC_QCM ;
/
