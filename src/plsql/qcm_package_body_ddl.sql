----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik, Evan Phelps 
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

  /* Some state variables 
  C_STAT_QCM_PREP      CONSTANT VARCHAR2(1) := 'P';
  C_STAT_QCM_STAGE     CONSTANT VARCHAR2(1) := 'S';
  C_STAT_QCM_CASE      CONSTANT VARCHAR2(1) := 'A';
  C_STAT_QCM_FTP       CONSTANT VARCHAR2(1) := 'F';
  C_STAT_QCM_RES       CONSTANT VARCHAR2(1) := 'R';
  C_STAT_QCM_ERROR     CONSTANT VARCHAR2(1) := 'E';
  C_STAT_QCM_SUCCESS   CONSTANT VARCHAR2(1) := 'C'; */



FUNCTION GET_CONSTANT(i_const IN VARCHAR)  
RETURN VARCHAR2 DETERMINISTIC AS
res VARCHAR2(2); 
BEGIN
   execute immediate 'begin :res := '||i_const ||'; end;' using out res;     
   RETURN res;
END GET_CONSTANT;

  PROCEDURE ex_tr_qcm(
      p_trans_t0 qcm_meta.tx_start%type,
      p_site_id NUMBER DEFAULT NULL,
      p_batch_id OUT NUMBER,
      --sessionid OUT varchar2, --vktest
      m_cur   IN OUT  SYS_REFCURSOR,
      p_max_days NUMBER DEFAULT 120
      )
  IS
    PRCDR infolog.procedure_name%TYPE := 'ex_tr_qcm';


    m_session_id       raw(16); --vktest

    m_batch_id         NUMBER := qcm_batch_id_seq.NEXTVAL;
    m_time_start       DATE := SYSDATE;
    m_trans_t0         DATE := p_trans_t0;
    m_site_id          NUMBER := p_site_id;
    m_max_days         NUMBER := p_max_days;
    m_pkg              VARCHAR2(100 BYTE) := 'PKG_SCSQC_QCM';
    m_prc              VARCHAR2(100 BYTE) := 'EX_TR_QCM';



  BEGIN

    IF m_trans_t0 IS NULL THEN
      RAISE_APPLICATION_ERROR(ERRNUM_LAST_INCOMPLETE,
      ERRMSG_LAST_INCOMPLETE || 'Site ' || m_site_id
        || ' has no previously completed batches.');
    END IF;
    IF sysdate-m_trans_t0 > m_max_days THEN
      RAISE_APPLICATION_ERROR(ERRNUM_INCREMENTAL_TOO_BIG,
      ERRMSG_INCREMENTAL_TOO_BIG || ' Transaction period is ' || ROUND(sysdate-
      m_trans_t0) || ' days; max is ' || m_max_days || ' days.');
    END IF;


    --sys.dbms_xs_sessions.create_session('sqctest', m_session_id);
    --sessionid := rawtohex(m_session_id);
    --sys.dbms_xs_sessions.attach_session(m_session_id, null);

   INSERT
    INTO
      HSSC_ETL.QCM_META
      (
        BATCH_ID,
        BATCH_TYPE,
        BATCH_STATUS,
        QCM_SITE,
        TX_START
      )
      VALUES
      (
        m_batch_id,
        m_pkg,
        C_STAT_QCM_PREP,
        m_site_id, 
        m_time_start
      );
    COMMIT;
    
    -- pause before inserting into qcm_meta
    SYS.DBMS_LOCK.SLEEP (2);


    -- beginning of select cursor
    OPEN m_cur FOR

       -- CDW extraction logic

      SELECT * FROM
      (
        SELECT /*+ PARALLEL 4 */ distinct
          rank() over ( partition by v.visit_id
                        order by px.proc_end_date NULLS LAST,
                                 px.proc_code,
                                 qcmc.res_case_id NULLS LAST,
                                 px.procedure_id
                      ) as "IDX",
  
          -- encounter (CDW.VISIT)
          v.HTB_ENC_ID_ROOT as "DATASOURCE_ROOT",
          v.HTB_ENC_ACT_ID as "HTB_ENC_ACT_ID",
          v.visit_id as "VISIT_ID",
  
          qcmc.res_case_id AS "QCM_Casenum",
          
          -- site/cntrl/meta/case details
          qs.res_site as "Site",
          px.procedure_id as "PROCEDURE_ID",
          vd.htb_patient_id_ext as "MRN",
          vd.htb_patient_id_ext as "MPI_LID",
          m_batch_id as "BATCH_ID",
  
          /*      Patients   */
          p.birth_date as "Patients.DOB",
          p.first_name as "Patients.First_Name",
          p.last_name as "Patients.Last_Name",
          SUBSTR(p.middle_name, 1, 1) as "Patients.Middle_Initial",
          p.sex as "Patients.Sex",
          p.race as "Patients.Race",
          p.addr_1 as "Patients.Address",
          p.addr_2 as "Patients.Address2",
          p.city as "Patients.City",
          p.state as "Patients.State",
          p.zip as "Patients.Zip",
          p.country as "Patients.Country",
          p.county as "Patients.County",
          p.home_phone as "Patients.Phone",
          p.email_address as "Patients.Email",
          p.ethnicity as "Patients.Ethnicity_Hispanic",
  
          /* Studies */
          px.proc_end_date as "Studies.OP_Date",
          CASE WHEN px.proc_code_type = 'CPT4' THEN
            px.proc_code ELSE NULL
          END AS "Studies.CPT_Code",
          CASE WHEN px.proc_code_type IN ('ICD-9-CM', 'ICD-10-PCS') THEN
              px.proc_code ELSE NULL
          END AS "Studies.ICD9_Code",
  --        vd.admission_source as "Studies.Admission_Source", (TODO map)
          vd.admission_date as "Studies.Admit_Date",
          to_char(vd.discharge_date, 'YYYY-MM-DD') as "Studies.Discharge_Date",
          to_char(vd.discharge_date, 'HH24:MI') as "Studies.Discharge_Time",
          v.visit_id as "Studies.Encounter_Number"
  
          /* Discharge */
          --vd.discharge_disposition as "Discharge_Destination", (TODO map)
          --?.? as "Discharge.Still_In_Hospital", (TODO map)
  --        p.deceased_ind as "Discharge.Death", (TODO map)
  --        p.death_date as "Discharge.Death_Date"
  
  /* TODO get one height/weight only, if we can distinguish pre-/post-op
  --        CASE WHEN vtl.observation_type = 'HEIGHT' THEN
  --          vtl.vital_value_num ELSE NULL
  --        END AS "Preop.Height",
  --
  --        CASE WHEN vtl.observation_type = 'HEIGHT' THEN
  --          vtl.vital_value_unit ELSE NULL
  --        END AS "Preop.Height_Unit",
  --
  --        CASE WHEN vtl.observation_type = 'WEIGHT' THEN
  --          vtl.vital_value_num ELSE NULL
  --        END AS "Preop.Weight",
  --
  --        CASE WHEN vtl.observation_type = 'WEIGHT' THEN
  --          vtl.vital_value_unit ELSE NULL
  --        END AS "Preop.Weight_Unit"
  */
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
  
        -- SQC targeted procedures only
        INNER JOIN qcm_proc_codes pxg
           ON (    px.proc_code_type = pxg.code_sys
               AND px.proc_code = pxg.code_val )
               
        -- get existing sqc case number, if exists
        LEFT OUTER JOIN qcm_case qcmc
           ON ( v.visit_id = qcmc.visit_id )
           
        -- visit(visit_id) = vital(htb_enc_act_id)
  --      LEFT OUTER JOIN cdw.vital vtl
  --      ON
  --        (
  --          v.visit_id = vtl.htb_enc_act_id
  --        )
        -- patient(patient_id) = visit(patient_id)
        INNER JOIN cdw.patient p
           ON
            (
              p.patient_id = v.patient_id
            )
        -- get tx_start of previous successful batch
        --    for now, let's do this in client app, which will pass via m_trans_t0
  --      INNER JOIN qcm_meta qmeta
  --         ON (     qs.res_site = qmeta.qcm_site
  --              AND C_STAT_QCM_SUCCESS = qmeta.batch_status
  --              AND not exists ( select 1
  --                               from qcm_meta qmeta2
  --                               where qmeta.qcm_site = qmeta2.qcm_site
  --                                 and qmeta2.tx_start > qmeta.tx_start )
  --            )
          -- ;
          -- extra filters
          
        WHERE
           -- configurable procedure start date > T - P
              px.proc_end_date > (sysdate - m_max_days)
           -- one-time date cutoff for initial extract
          AND px.proc_end_date > to_date('2016-04-01', 'YYYY-MM-DD')
           -- modified since last extract. TODO sysdate-7 with last batch time
          AND v.htb_enc_act_id in ( select enc_stg.enc_act_id
                                    from cdw.enc_staging enc_stg
                                    where enc_stg.processed_dt > m_trans_t0
                                  )
          AND qs.res_site = to_char(m_site_id)
      )
      WHERE idx = 1
      ;


    p_batch_id := m_batch_id;

    -- update this batch for staging completion
    UPDATE HSSC_ETL.QCM_META
      SET BATCH_STATUS =  C_STAT_QCM_STAGE
    WHERE BATCH_ID = m_batch_id;
    COMMIT;  

  END ex_tr_qcm;

END PKG_SCSQC_QCM ;

/
