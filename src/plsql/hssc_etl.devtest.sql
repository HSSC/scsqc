/******** Testing Extraction Procedure in dtdev *********/
ALTER SESSION SET CURRENT_SCHEMA=HSSC_ETL;

DECLARE
  m_qcmextresults PKG_SCSQC_QCM.QCMTableType;
  m_cur           SYS_REFCURSOR;
  
BEGIN

  PKG_SCSQC_QCM.ex_tr_qcm(SYSDATE, 20, m_cur);
  LOOP
      FETCH
        m_cur BULK COLLECT 
      INTO
        m_qcmextresults  LIMIT 25;
      EXIT WHEN m_cur%NOTFOUND;
    
    FOR i IN m_qcmextresults.first .. m_qcmextresults.last
    LOOP
       DBMS_OUTPUT.PUT_LINE( m_qcmextresults(i).Site || ',' 
       || m_qcmextresults(i).MRN || ',' || m_qcmextresults(i).DOB || ',' 
       || m_qcmextresults(i).OP_Date
       );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('------------------------------');
  END LOOP;
  CLOSE m_cur;
   
END ;
/
