
import os
import sys
import traceback
import cx_Oracle
import csv

## local imports
from sqcbase import config
from sqcbase import logger
from transfer import sftp_transfer



class qcm_db:

    def __init__(self, options):
        self.ocur = None
        self.mcur = None
        self.conn_str = options["app"]
        self.tnsenv = options["tns_env"]
        try:
            os.environ['TNS_ADMIN'] = self.tnsenv
            self.db = cx_Oracle.connect(self.conn_str)
            self.mcur = self.db.cursor()

        except cx_Oracle.DatabaseError, err:
            sys.stderr.write('ERROR: %s\n' % str(err))
            traceback.print_exc()

    def now(self):
        q_test = 'select sysdate from dual';
        now = self.mcur.execute(q_test);
        return now.fetchone()[0];

    def get_cur(self):
        if self.ocur:
            try:
                self.ocur.close()
            except:
                pass
        self.ocur = self.db.cursor()
        return self.ocur

    def extract(self):
      self.get_cur()
      now = self.now()
      nmax = 20;
      out = self.mcur.callproc( "HSSC_ETL.PKG_SCSQC_QCM.ex_tr_qcm", [now, nmax, self.ocur] )
      rows = self.ocur.fetchall()
      f = open("job_history.csv", "w")
      writer = csv.writer(f, lineterminator="\n", quoting=csv.QUOTE_NONNUMERIC)
      for row in rows:
        writer.writerow(row)
      f.close()


    def __del__(self):
        if self.mcur:
          self.mcur.close()
        if self.ocur:
          self.ocur.close()
        if self.db:
          self.db.close()


class sqc_driver:

    def __init__(self, options):
        self.options = options
        self.config_path = None
        self.config_vars = None

        sys.stderr.write("Reading configuration file: %s\n" % options.conf)
        try:
            with open (options.conf, 'r') as f:
                f.close()
            self.config_path = options.conf
            self.config_vars = config.getConfigParser(self.config_path)
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err))
            traceback.print_exc()
            sys.exit(err.errno)


    def run(self):
        db = qcm_db( config.getConfigSectionMap( self.config_vars, "db" ))
        print db.now().strftime('%Y/%m/%d %H:%M:%S')
        db.extract()
        del(db)
        print 'success'

