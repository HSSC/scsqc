
import os
import sys
import traceback
import cx_Oracle
import csv
import paramiko
import datetime
#from dateutil import tz

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
        now = datetime.date(2016, 04, 01)
        nsite = 1007;
        batch_id = 99999999
        ## call stored procedure with parameters
        print '--> Calling "HSSC_ETL.PKG_SCSQC_QCM.ex_tr_qcm(%s,%s,%s,cur)' % (now, nsite, batch_id)
        proc_output = self.db.get_mcur().callproc( "HSSC_ETL.PKG_SCSQC_QCM.ex_tr_qcm", [now, nsite, batch_id, self.ocur] )
        self.batch_id = proc_output[2]

        ## get description of columnar payload
        skip_columns = [ 'IDX' ]
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

        self.pfile = 'qcm_site-%s_batch-%05d.csv' % (nsite, self.batch_id)
        f = open(self.pfile, "w")
        writer = csv.DictWriter(f, lineterminator="\n", quoting=csv.QUOTE_NONNUMERIC, fieldnames=self.qcm_dict)
        writer.writeheader()

        meta_numrows = 0
        batch_count = 0
        while True:
            batch_count += 1
            rows = self.ocur.fetchmany(459)
            if rows == [] or batch_count > 2:
                break
            meta_numrows += len(rows)
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
                    if head[i][0] in skip_columns:
                      continue
                    qcm_case[head[i][0]] = self.transform(row[i])
                in_qcm_case += ( ", ".join( [ "%s" % key for key in qcm_case ] ))
                in_qcm_case += " ) VALUES ( "
                in_qcm_case += ( ", ".join( [ "%s" % qcm_case[key] for key in qcm_case ] ))
                in_qcm_case += ")\n"
                writer.writerow(qcm_payload)
                if meta_numrows % 100 == 0 and meta_numrows > 0:
                    in_qcm_case += "SELECT * FROM dual"
                    self.db.get_mcur().execute(in_qcm_case)
                    self.db.get_conn().commit()
                    in_qcm_case = (' INSERT ALL \n')

            in_qcm_case += "SELECT * FROM dual"
        if meta_numrows > 0:
                self.db.get_mcur().execute(in_qcm_case)
                self.db.get_conn().commit()


        ## all qcm_case records have been successfully populated at this point
        val = 0
        st_qcm = self.db.get_mcur().callfunc( "HSSC_ETL.PKG_SCSQC_QCM.GET_CONSTANT", val, ['PKG_SCSQC_QCM.C_STAT_QCM_CASE'] )
        up_qcm_meta =  'UPDATE HSSC_ETL.QCM_META SET BATCH_STATUS = \'%s\', QCM_DAT_NREC = %d WHERE BATCH_ID = %d' % (st_qcm, meta_numrows, self.batch_id)
        self.db.get_mcur().execute(up_qcm_meta)
        self.db.get_conn().commit()

        f.close()

        ## qcm_cntrl insert
        in_qcm_cntrl = "INSERT INTO HSSC_ETL.QCM_CNTRL (LOCAL_CASE_ID, BATCH_ID) "
        in_qcm_cntrl += "SELECT LOCAL_CASE_ID, BATCH_ID FROM HSSC_ETL.QCM_CASE WHERE BATCH_ID = "
        in_qcm_cntrl += str(self.batch_id)
        self.db.get_mcur().execute(in_qcm_cntrl)
        self.db.get_conn().commit()

        ## all qcm_cntrl records have been added at this point
        val = 0
        st_qcm = self.db.get_mcur().callfunc( "HSSC_ETL.PKG_SCSQC_QCM.GET_CONSTANT", val, ['PKG_SCSQC_QCM.C_STAT_QCM_CNTRL'] )
        up_qcm_meta =  'UPDATE HSSC_ETL.QCM_META SET BATCH_STATUS = \'%s\' WHERE BATCH_ID = %d' % (st_qcm, self.batch_id)
        self.db.get_mcur().execute(up_qcm_meta)
        self.db.get_conn().commit()

        ## db transaction completed

        tx_compl = datetime.datetime.now()
        #from_zone = tz.tzutc()
        #to_zone = tz.tzlocal()
        #tx_compl.replace(tzinfo=from_zone)
        up_qcm_meta =  'UPDATE HSSC_ETL.QCM_META SET TX_COMPL = :t WHERE BATCH_ID = %d' % (self.batch_id)
        self.db.get_mcur().execute(up_qcm_meta, {'t':tx_compl})
        self.db.get_conn().commit()

        ##cursor goes out of scope here. extract/update tables qcm_meta, qcm_cntrl, qcm_case done

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
            meta_rate = trn_dt.microseconds*1.E-3
            meta_size = t_stat.st_size
            meta_modt = datetime.datetime.fromtimestamp(t_stat.st_mtime)
            print '--> Transferred %s with size %.1f bytes in %.2f ms' % ( self.pfile, meta_size, meta_rate)
            print '--> Last Modified time: ', \
                       meta_modt.strftime('%YYYY/%m/%d %H:%M:%S')

            ## qcm_meta update
            in_qcm_meta = "UPDATE HSSC_ETL.QCM_META SET QCM_DAT_FNAME = \'%s\', QCM_DAT_SIZE = %.1f " % (self.pfile, meta_size)
            #in_qcm_meta += ", QCM_DAT_RATE = %.2f WHERE BATCH_ID = %d" % (meta_rate, self.batch_id) #, QCM_DAT_MOD = to_date( \'%s\', \'YYYY-MM-DD HH:MI:SS\') WHERE BATCH_ID = " (
            in_qcm_meta += ", QCM_DAT_RATE = %.2f, QCM_DAT_MOD = :t WHERE BATCH_ID = %d" % (meta_rate, self.batch_id)
            self.db.get_mcur().execute(in_qcm_meta, {'t':meta_modt})
            self.db.get_conn().commit()

            ## all qcm_cntrl records have been added at this point
            val = 0
            st_qcm = self.db.get_mcur().callfunc( "HSSC_ETL.PKG_SCSQC_QCM.GET_CONSTANT", val, ['PKG_SCSQC_QCM.C_STAT_QCM_FTP'] )
            up_qcm_meta =  'UPDATE HSSC_ETL.QCM_META SET BATCH_STATUS = \'%s\' WHERE BATCH_ID = %d' % (st_qcm, self.batch_id)
            self.db.get_mcur().execute(up_qcm_meta)
            self.db.get_conn().commit()
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



