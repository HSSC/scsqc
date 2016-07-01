----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: Package body for QCM Ex/Tr
-- Created: Thu Jun 09 2016
----------------------------------------------

--------------------------------------------------------
--  DDL for Package Body PKG_SCSQC_QCM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HSSC_ETL"."PKG_SCSQC_QCM" 
AS

  PKG infolog.package_name%TYPE := 'PKG_SCSQC_QCM';

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
      p_site_id NUMBER DEFAULT NULL,
      p_batch_id OUT NUMBER,
      --sessionid OUT varchar2, --vktest
      m_cur   IN OUT  SYS_REFCURSOR,    
      p_max_days NUMBER DEFAULT 90
      )
  IS
    PRCDR infolog.procedure_name%TYPE := 'ex_tr_qcm';
    
    
    m_session_id       raw(16); --vktest
    
    m_batch_id         NUMBER := qcm_batch_id_seq.NEXTVAL;
    m_batch_stat_last  CHAR(1);
    m_time_start       DATE := SYSDATE;
    m_time_end         DATE := SYSDATE;
    m_trans_t0         DATE := p_trans_t0;
    m_trans_t1         DATE := m_time_start;
    m_row_count        NUMBER := 0;
    m_site_id          NUMBER := p_site_id;
    m_max_days         NUMBER := p_max_days;
    m_pkg              VARCHAR2(100 BYTE) := 'PKG_SCSQC_QCM';
    m_prc              VARCHAR2(100 BYTE) := 'EX_TR_QCM';
       
    

  BEGIN

    IF sysdate-m_trans_t0 > m_max_days THEN
      RAISE_APPLICATION_ERROR(ERRNUM_INCREMENTAL_TOO_BIG,
      ERRMSG_INCREMENTAL_TOO_BIG || ' Transaction period is ' || ROUND(sysdate-
      m_trans_t0) || ' days; max is ' || m_max_days || ' days.');
    END IF;


    --sys.dbms_xs_sessions.create_session('sqctest', m_session_id);
    --sessionid := rawtohex(m_session_id);
    --sys.dbms_xs_sessions.attach_session(m_session_id, null);
    
    OPEN m_cur FOR
    
       -- CDW extraction logic
       
      SELECT
        /*+ PARALLEL 4 */

        -- encounter (CDW.VISIT)
        v.visit_id as "VISIT_ID",        
        v.HTB_ENC_ID_ROOT as "DATASOURCE_ROOT",
        v.HTB_ENC_ACT_ID as "HTB_ENC_ACT_ID",
        
        -- site details (HSSC_ETL.QCM_SITE)
        
        qs.res_site as "Site",
        -- procedure ( CDW.PROCEDURE)
        px.procedure_id as "PROCEDURE_ID",
        --px.datasource_id,
        -- MRN (CDW.PATIENT_ID_MAP)
        
        pim.mpi_lid as "MRN",
        pim.mpi_lid as "MPI_LID",
        m_batch_id as "BATCH_ID",
        -- DOB (CDW.PATIENT)
        
        /*      Patients   */
        p.birth_date as "Patients.DOB",
        p.first_name as "Patients.First_Name",
        p.last_name as "Patients.Last_Name",
        SUBSTR(p.middle_name, 0, 1) as "Patients.Middle_Initial",
        p.sex as "Patients.Sex",
        p.race as "Patients.Race",
        p.addr_1 as "Patients.Address",
        p.addr_2 as "Patients.Address2",
        p.city as "Patients.City",
        p.state as "Patients.State",
        p.zip as "Patients.Zip",
        p.country as "Patients.Country",
        p.county as "Patients.County",
        p.home_phone as "Patients.Phone",  -- we have home, work, mobile (QCM)
        p.email_address as "Patients.Email",
        -- p.? as "Patients.Insurance",  -- LOC
        p.ethnicity as "Patients.Ethnicity_Hispanic",
        
        --p.patient_id,
        
        /* Studies */
        px.proc_end_date as "Studies.OP_Date",
        CASE WHEN px.proc_code_type = 'CPT4' THEN
          px.proc_code ELSE NULL
        END AS "Studies.CPT_Code",
        CASE WHEN px.proc_code_type = 'ICD-9-CM' THEN
            px.proc_code ELSE NULL
        END AS "Studies.ICD9_Code",
        -- ?.? as "Studies.Surgeon_ID",
        -- ?.? as "Studies.Surgeon_First_Name",
        -- ?.? as "Studies.Surgeon_Middle_Initial",
        -- ?.? as "Studies.Surgeon_Last_Name",
        -- ?.? as "Studies.Surgical_Priority",
        vd.admission_source as "Studies.Admission_Source",
        vd.admission_date as "Studies.Admit_Date",
        to_char(vd.discharge_date, 'YYYY-MM-DD') as "Studies.Discharge_Date",
        to_char(vd.discharge_date, 'HH24:MI') as "Studies.Discharge_Time",
        v.visit_id as "Studies.Encounter_Number",
        
        /* Discharge */
        --vd.discharge_disposition as "Discharge_Destination",
        --?.? as "Discharge.Still_In_Hospital",
        p.deceased_ind as "Discharge.Death",
        p.death_date as "Discharge.Death_Date",

        CASE WHEN vtl.observation_type = 'HEIGHT' THEN
          vtl.vital_value_num ELSE NULL
        END AS "Preop.Height",
        
        CASE WHEN vtl.observation_type = 'HEIGHT' THEN
          vtl.vital_value_unit ELSE NULL
        END AS "Preop.Height_Unit",
        
        CASE WHEN vtl.observation_type = 'WEIGHT' THEN
          vtl.vital_value_num ELSE NULL
        END AS "Preop.Weight",
        
        CASE WHEN vtl.observation_type = 'WEIGHT' THEN
          vtl.vital_value_unit ELSE NULL
        END AS "Preop.Weight_Unit"
        
      FROM
        hssc_etl.qcm_site qs
      
      -- visit htb_enc_id_root = qcm_site datasource_root
      INNER JOIN cdw.visit v
      ON
        (
          v.htb_enc_id_root = qs.datasource_root
        )
      
      -- visit_detail(visit_id) = visit(visit_id)
      INNER JOIN cdw.visit_detail vd
      ON
        (
          vd.visit_id = v.visit_id
        )
      
      -- procedure(visit_id) = visit(visit_id)
      INNER JOIN cdw.procedure px
      ON
        (
          px.visit_id = v.visit_id
        )

      -- visit(visit_id) = vital(htb_enc_act_id)
      LEFT OUTER JOIN cdw.vital vtl
      ON
        (
          v.visit_id = vtl.htb_enc_act_id
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
      
      AND
        -- restrict to a given site
        qs.res_site = to_char(m_site_id);
        
    -- remove this line and revoke execute on this call for HSSC_ETL/sqctest
    SYS.DBMS_LOCK.SLEEP (3);
    
    m_time_end := SYSDATE;  
    p_batch_id := m_batch_id;
    
    INSERT
    INTO
      QCM_META
      (
        BATCH_ID,
        BATCH_TYPE,
        TX_START,
        TX_COMPL
      )
      VALUES
      (
        m_batch_id,
        m_pkg,
        m_time_start,
        m_time_end
      );
        COMMIT;
    
  END ex_tr_qcm;
  
END PKG_SCSQC_QCM ;

/

