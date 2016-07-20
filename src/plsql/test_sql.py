import cx_Oracle
from datetime import date
import os
import csv

os.environ['TNS_ADMIN'] = '/home/venkat/work/dev/sql_conn/'
c_str = "/@myserv"; conn = cx_Oracle.connect(c_str)
q_test = 'select sysdate from dual'; cur = conn.cursor(); out = cur.execute(q_test); res = out.fetchall();
print res

cur_extr = conn.cursor(); cur_fetch = conn.cursor(); now = date(2016,6,15); nmax = 20;
out = cur_extr.callproc( "HSSC_ETL.PKG_SCSQC_QCM.ex_tr_qcm", [now, nmax, cur_fetch] )


cur_fetch.arraysize = 50

rows = cur_fetch.fetchall()
print cur_fetch.rowcount
print cur_fetch.description
for row in rows:
  print row
