----------------------------------------------
-- Project: SCSQC
-- Author: Venkat Kaushik 
-- Purpose: load sequences and triggers
-- Created: Thu Jun 09 2016
----------------------------------------------

spool build_output_02.log
set pagesize 0
SET SERVEROUTPUT ON;

prompt "QCM02: creating sequences and triggers";
@qcm_seq_trig.sql
/
prompt "QCM02: done"

