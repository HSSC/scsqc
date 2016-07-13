
import os
import sys
import cx_Oracle
import csv
import paramiko
import datetime
import logging

## local imports
from sqcbase import config
from sqcbase import logger
from transfer import sftp_transfer



class qcm_db:

    def __init__(self, db_options, log):
        self.ocur = None ## secondary cursor
        self.mcur = None ## main cursor
        self.db = None ## database connection object
        self.opts = db_options
        self.log = log
        self.conn_str = self.opts["app"]
        try:
            os.environ['TNS_ADMIN'] = self.opts["tns_env"]
            self.db = cx_Oracle.connect(self.conn_str)
            self.mcur = self.db.cursor()

        except cx_Oracle.DatabaseError, err:
            self.log.exception('ERROR: %s\n' % str(err), exc_info=1)

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


        self.db_opts = config.getConfigSectionMap( self.config_vars, "db" )
        self.pl_opts = config.getConfigSectionMap( self.config_vars, "payload" )
        self.tr_opts = config.getConfigSectionMap( self.config_vars, "sftp" )
        self.log = logger.logInit(self.options.logLevel, self.pl_opts['log_path'], type(self).__name__)
        self.db = qcm_db(self.db_opts, self.log)

    def transform(self, item):
        if isinstance(item, datetime.datetime):
            item = item.strftime('%m/%d/%Y')
        elif isinstance(item, str):
            item = ( "\'%s\'" % item )
        return item

    def extract(self):
        ## get a cursor
        self.ocur = self.db.get_ocur()

        ## set parameters for stored procedure
        base_time = datetime.datetime.strptime('000001', '%H%M%S').time()
        proc_tx_start = datetime.datetime.combine(
                              (datetime.date.today() - datetime.timedelta(days=int(self.pl_opts['ndays_txstart'])) ), base_time )
        proc_site_id = int(self.pl_opts['site_id'])
        val = 0
        st_qcm = self.db.get_mcur().callfunc( "HSSC_ETL.PKG_SCSQC_QCM.GET_CONSTANT", val, ['PKG_SCSQC_QCM.C_STAT_QCM_FTP'] )
        sel_tx_start = "SELECT qm.TX_START FROM HSSC_ETL.QCM_META qm WHERE "
        sel_tx_start += "QCM_SITE = \'%d\' and BATCH_STATUS = \'%s\'" % ( proc_site_id, st_qcm)
        sel_tx_start += " AND NOT EXISTS ( SELECT 1 FROM HSSC_ETL.QCM_META qm2 WHERE qm2.TX_START > qm.TX_START "
        sel_tx_start += " AND qm.QCM_SITE = qm2.QCM_SITE AND qm2.BATCH_STATUS = \'%s\' )" % st_qcm

        if self.options.logLevel == 'VERBOSE':
            self.log.log(logging.INFO, sel_tx_start)
        proc_batch_id = 99999999 ## we will get the batch_id from the stored proc, just initialize with dummy (large) value
        proc_start_days = int(self.pl_opts['ndays_max_txstart'])

        ## get the start date for extraction
        try:
            ## get the last extraction date
            pst_cur = self.db.get_mcur().execute(sel_tx_start)
            txstart = pst_cur.fetchone()
            if txstart != None:
                if len(txstart) > 0:
                    txstart = txstart[0]
                    timenow = datetime.datetime.now()
                    delta = timenow - txstart
                    ## expect extraction to occur daily
                    if delta.days >= 1:
                        proc_tx_start = txstart
            else:
                proc_tx_start =  datetime.datetime.combine( datetime.date(2016, 04, 01), base_time )
        ## if we can't get start date for last extraction, just use default
        except cx_Oracle.DatabaseError, err:
            pass

        ## call stored procedure with parameters
        self.log.debug( 'Calling procedure with p_trans_t0 = %s for p_site_id = %s' % (proc_tx_start, proc_site_id))
        proc_output = self.db.get_mcur().callproc( "HSSC_ETL.PKG_SCSQC_QCM.ex_tr_qcm", [proc_tx_start, proc_site_id, proc_batch_id, self.ocur, proc_start_days] )
        self.batch_id = proc_output[2]

        ## get description of columnar payload
        skip_columns = [ 'IDX' ]
        head = self.ocur.description

        ## sniff csv header from qc-mitt
        try:
            with open (self.pl_opts['qcm_header_path'], 'r') as f:
                dialect = csv.Sniffer().sniff(f.readline())
                f.seek(0)
                reader = csv.reader(f, dialect)
                ## we know we need only first row (headers) from qc-mitt
                for item in reader:
                    self.qcm_dict = item
                    break
                f.close()
        except IOError, err:
            self.log.error('ERROR: reading template file %s\n%s\n' % ( self.pl_opts['qcm_header_path'] , str(err)))
            self.log.exception("exception:", exc_info=1)
            sys.exit(err.errno)


        ## process rows and serialise
        ## mapping between payload columns and sniffed column header is 1-to-1
        ## any additional columns in payload will be a part of qcm_case (internal use only)
        fc_time = datetime.datetime.now().strftime('%Y%m%d')
        self.pfile = self.pl_opts['csv_file_prefix'] + ( 'site_%s_%s_%05d.csv' % (proc_site_id, fc_time, self.batch_id) )
        self.ppath = self.pl_opts['csv_local_path']
        try:
            fpath = os.path.join(self.ppath, self.pfile)
            f = open(fpath, "wb")
            #writer = csv.DictWriter(f, lineterminator="\r\n", dialect='excel', quoting=csv.QUOTE_NONE, fieldnames=self.qcm_dict)
            writer = csv.DictWriter(f, dialect='excel', escapechar='\\', fieldnames=self.qcm_dict)
            writer.writeheader()
        except IOError, err:
            self.log.error('ERROR: reading template file %s\n%s\n' % ( fpath , str(err)), exc_info=1)
            sys.exit(err.errno)

        meta_numrows = 0
        batch_count = 0
        batch_size = int(self.pl_opts['batch_size'])
        batch_maxcnt = int(self.pl_opts['batch_maxnum'])
        while True:
            batch_count += 1
            rows = self.ocur.fetchmany(batch_size)
            if rows == [] or batch_count > batch_maxcnt:
                if batch_count > batch_maxcnt:
                    log.warn('Too many rows. Exceeded %d batches of %d records' % (batch_count, batch_size))
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
                    qcm_payload[head[i][0]] =  row[i] ## self.transform(row[i])
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

            if self.options.logLevel == 'VERBOSE':
                self.log.log(logging.INFO, in_qcm_case)

            in_qcm_case += "SELECT * FROM dual"
        if meta_numrows > 0:
                self.db.get_mcur().execute(in_qcm_case)
                self.db.get_conn().commit()


        ## all qcm_case records have been successfully populated at this point
        val = 0
        st_qcm = self.db.get_mcur().callfunc( "HSSC_ETL.PKG_SCSQC_QCM.GET_CONSTANT", val, ['PKG_SCSQC_QCM.C_STAT_QCM_CASE'] )
        up_qcm_meta =  'UPDATE HSSC_ETL.QCM_META SET BATCH_STATUS = \'%s\', QCM_DAT_NREC = %d WHERE BATCH_ID = %d' % (st_qcm, meta_numrows, self.batch_id)
        if self.options.logLevel == 'VERBOSE':
            self.log.log(logging.INFO, up_qcm_meta)
        self.db.get_mcur().execute(up_qcm_meta)
        self.db.get_conn().commit()

        f.close()

        ## qcm_cntrl insert
        in_qcm_cntrl = "INSERT INTO HSSC_ETL.QCM_CNTRL (LOCAL_CASE_ID, BATCH_ID) "
        in_qcm_cntrl += "SELECT LOCAL_CASE_ID, BATCH_ID FROM HSSC_ETL.QCM_CASE WHERE BATCH_ID = "
        in_qcm_cntrl += str(self.batch_id)
        if self.options.logLevel == 'VERBOSE':
            self.log.log(logging.INFO, in_qcm_cntrl)
        self.db.get_mcur().execute(in_qcm_cntrl)
        self.db.get_conn().commit()

        ## all qcm_cntrl records have been added at this point
        val = 0
        st_qcm = self.db.get_mcur().callfunc( "HSSC_ETL.PKG_SCSQC_QCM.GET_CONSTANT", val, ['PKG_SCSQC_QCM.C_STAT_QCM_CNTRL'] )
        up_qcm_meta =  'UPDATE HSSC_ETL.QCM_META SET BATCH_STATUS = \'%s\' WHERE BATCH_ID = %d' % (st_qcm, self.batch_id)
        if self.options.logLevel == 'VERBOSE':
            self.log.log(logging.INFO, up_qcm_meta)
        self.db.get_mcur().execute(up_qcm_meta)
        self.db.get_conn().commit()

        ## db transaction completed

        tx_compl = datetime.datetime.now()
        up_qcm_meta =  'UPDATE HSSC_ETL.QCM_META SET TX_COMPL = :t WHERE BATCH_ID = %d' % (self.batch_id)
        self.db.get_mcur().execute(up_qcm_meta, {'t':tx_compl})
        if self.options.logLevel == 'VERBOSE':
            self.log.log(logging.INFO, up_qcm_meta)
        self.db.get_conn().commit()

        ##cursor goes out of scope here. extract/update tables qcm_meta, qcm_cntrl, qcm_case done

    def transfer(self):

        ## get configuration
        remote_paths = self.tr_opts['remotedirs'].split(',')
        host= self.tr_opts['host']
        port= int(self.tr_opts['port'])
        keyfile= self.tr_opts['pubkey']
        local_fpath = os.path.join(self.ppath, self.pfile)
        try:
            trn_t0 = datetime.datetime.now()
            handle, transport = sftp_transfer.sftp_connect(self.tr_opts['host'], self.tr_opts['port'], self.tr_opts['user'], keyfile)
            t_stat = paramiko.sftp_attr.SFTPAttributes()
            for idir in remote_paths:
                remote_fpath = os.path.join(idir.strip(), self.pfile)
                t_stat, t_rate = sftp_transfer.sftp_put(handle, local_fpath, remote_fpath)
            trn_t1 = datetime.datetime.now()
            trn_dt = trn_t1 - trn_t0
            meta_rate = trn_dt.microseconds*1.E-3
            meta_size = t_stat.st_size
            meta_modt = datetime.datetime.fromtimestamp(t_stat.st_mtime)
            self.log.info('Transferred %s with size %.1f bytes in %.2f ms' % ( self.pfile, meta_size, meta_rate))
            self.log.info('Payload file last modified at %s' % meta_modt) #.strftime('%Y/%m/%d %H:%M:%S'))

            ## sftp transfer successful
            val = 0
            st_qcm = self.db.get_mcur().callfunc( "HSSC_ETL.PKG_SCSQC_QCM.GET_CONSTANT", val, ['PKG_SCSQC_QCM.C_STAT_QCM_FTP'] )
            up_qcm_meta = "UPDATE HSSC_ETL.QCM_META SET "
            up_qcm_meta += 'TX_START=(SELECT CAST(FROM_TZ(CAST( '
            up_qcm_meta += '(SELECT TX_START from HSSC_ETL.QCM_META WHERE BATCH_ID = %d) AS TIMESTAMP), \'EST\') ' % self.batch_id
            up_qcm_meta += 'AT TIME ZONE \'UTC\' AS DATE) FROM DUAL) '
            up_qcm_meta += ", QCM_DAT_FNAME = \'%s\', QCM_DAT_SIZE = %.1f " % (self.pfile, meta_size)
            up_qcm_meta += ", QCM_DAT_RATE = %.2f, QCM_DAT_MOD = :t, BATCH_STATUS = \'%s\' WHERE BATCH_ID = %d" % (meta_rate, st_qcm, self.batch_id)
            if self.options.logLevel == 'VERBOSE':
                self.log.log(logging.INFO, up_qcm_meta)
            self.db.get_mcur().execute(up_qcm_meta, {'t':meta_modt})
            self.db.get_conn().commit()

        except paramiko.SSHException, err:
            self.log.exception('ERROR: %s\n' % str(err))
        finally:
            #os.remove(filepath)
            transport.close()


    def run(self):
        self.log.info('Starting Payload Extraction')
        self.extract()
        self.log.info('Starting Payload Transfer')
        self.transfer()
        self.log.info('Processing complete')
        del(self.db)


