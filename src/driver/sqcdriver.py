
import os
import sys
import traceback
import cx_Oracle
import csv
import paramiko
import datetime

## local imports
from sqcbase import config
from sqcbase import logger
from transfer import sftp_transfer



class qcm_db:

    def __init__(self, options):
        self.ocur = None ## secondary cursor
        self.mcur = None ## main cursor
        self.db = None ## database connection object
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

    def get_conn(self):
        return self.db

    def get_mcur(self):
        return self.mcur

    def get_ocur(self):
        if self.ocur:
            try:
                self.ocur.close()
            except:
                pass
        self.ocur = self.db.cursor()
        return self.ocur

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
        self.db = None
        self.mcur = None
        sys.stderr.write("\n--> Reading configuration file: %s\n" % options.conf)
        try:
            with open (options.conf, 'r') as f:
                f.close()
            self.config_path = options.conf
            self.config_vars = config.getConfigParser(self.config_path)
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err))
            traceback.print_exc()
            sys.exit(err.errno)

    def transform(self, item):
        if isinstance(item, datetime.datetime):
            item = item.strftime('%Y-%m-%d')
        elif isinstance(item, str):
            item = ( "\'%s\'" % item )
        return item

    def extract(self):
        ## get a cursor
        self.ocur = self.db.get_ocur()

        ## set parameters for stored procedure
        now = self.db.now()
        nsite = 1007;
        batch_id = 20
        ## call stored procedure with parameters
        proc_output = self.db.get_mcur().callproc( "HSSC_ETL.PKG_SCSQC_QCM.ex_tr_qcm", [now, nsite, batch_id, self.ocur] )
        batch_id = proc_output[2]

        ## get description of columnar payload
        head = self.ocur.description

        ## sniff csv header from qc-mitt
        with open ('/files/SCSQC_QCMitt_Empty.csv', 'r') as f:
            dialect = csv.Sniffer().sniff(f.readline())
            f.seek(0)
            reader = csv.reader(f, dialect)
            ## we know we need only first row (headers) from qc-mitt
            for item in reader:
                self.qcm_dict = item
                break
            f.close()

        ## process rows and serialise
        ## mapping between payload columns and sniffed column header is 1-to-1
        ## any additional columns in payload will be a part of qcm_case (internal use only)
        rows = self.ocur.fetchall()
        self.pfile = 'qcm_site-%s_batch-%05d.csv' % (nsite, batch_id)
        f = open(self.pfile, "w")
        writer = csv.DictWriter(f, lineterminator="\n", quoting=csv.QUOTE_NONNUMERIC, fieldnames=self.qcm_dict)
        writer.writeheader()
        in_qcm_case = ""
        in_qcm_case += (' INSERT ALL \n')
        for row in rows:
            qcm_payload = dict()
            qcm_case = dict()
            in_qcm_case += " INTO HSSC_ETL.QCM_CASE ( "
            for i in xrange(len(head)):
              if (head[i][0] in self.qcm_dict):
                qcm_payload[head[i][0]] = self.transform(row[i])
              else:
                qcm_case[head[i][0]] = self.transform(row[i])
            in_qcm_case += ( ", ".join( [ "%s" % key for key in qcm_case ] ))
            in_qcm_case += " ) VALUES ( "
            in_qcm_case += ( ", ".join( [ "%s" % qcm_case[key] for key in qcm_case ] ))
            in_qcm_case += ")\n"
            writer.writerow(qcm_payload)
        in_qcm_case += "SELECT * FROM dual"
        self.db.get_mcur().execute(in_qcm_case)
        self.db.get_conn().commit()

        ## qcm_cntrl insert
        in_qcm_cntrl = "INSERT INTO HSSC_ETL.QCM_CNTRL (LOCAL_CASE_ID, BATCH_ID) "
        in_qcm_cntrl += "SELECT LOCAL_CASE_ID, BATCH_ID FROM HSSC_ETL.QCM_CASE WHERE BATCH_ID = "
        in_qcm_cntrl += str(batch_id)

        self.db.get_mcur().execute(in_qcm_cntrl)
        self.db.get_conn().commit()

        f.close()

    def transfer(self):
        from transfer import sftp_transfer
        host='hssc-cdwr3-hsie-d.clemson.edu'
        port=22
        usern='transfer'
        keyfile= os.path.join('/files', 'hsie-d.key')
        filename = self.pfile
        remote_path = '/home/%s/testing/large/file/%s' % (usern, filename)
        filepath = os.path.join(os.getcwd(), filename)
        try:
            trn_t0 = datetime.datetime.now()
            handle, transport = sftp_transfer.sftp_connect(host, port, usern, keyfile)
            t_stat, t_rate = sftp_transfer.sftp_put(handle, filename, remote_path)
            trn_t1 = datetime.datetime.now()
            trn_dt = trn_t1 - trn_t0
            print '--> Transferred %s with size %.1f bytes in %.2f ms' % ( self.pfile, t_stat.st_size, trn_dt.microseconds*1.E-3)
            print '--> Last Modified time: ', \
                       datetime.datetime.fromtimestamp(t_stat.st_mtime).strftime('%Y/%m/%d %H:%M:%S')
        except paramiko.SSHException, err:
            sys.stderr.write('ERROR: %s\n' % str(err))
            traceback.print_exc()
        finally:
            #os.remove(filepath)
            transport.close()


    def run(self):
        self.db = qcm_db( config.getConfigSectionMap( self.config_vars, "db" ))
        print '--> Starting Payload Extraction : ', self.db.now().strftime('%Y/%m/%d %H:%M:%S')
        self.extract()
        print '--> Starting Payload Transfer : ', self.db.now().strftime('%Y/%m/%d %H:%M:%S')
        self.transfer()
        print '--> Finished at : ', self.db.now().strftime('%Y/%m/%d %H:%M:%S')
        del(self.db)




