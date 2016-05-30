from unittest import TestCase

import os, sys
from sqcbase import logger

class TestSqcBase(TestCase):

    ## unit test for logger
    def test_sqcbase_logger(self):
        from sqcbase import logger

        ## init a logfile using module
        logf = 'log_test.txt'
        if os.path.exists(logf):
            os.remove(logf)
        log = logger.logInit(logf, 2);

        ## check logfile was created
        self.assertEqual(os.path.exists(logf), True);
        if log:
            log.info('this is an info line')
            log.error('this is an error line')

        self.assertEqual(os.stat(logf).st_size, 104)
        os.remove(logf)

    def test_sqcbase_cmdline(self):
        from sqcbase.command_line import main
        main()

class TestReponse(TestCase):
    import response

    def test_response_cmdline(self):
        from response.command_line import main
        main()


    def test_response_extract(self):
        from response import qcm_sub as qcmr
        from sqcbase import logger
        #log = logger.logInit('mylog.txt')
        log = logger.logInit()
        verbosity = False

        CURDIR = os.path.dirname(os.path.abspath(__file__))
        infile = os.path.join(CURDIR, '../src/response/data/Response_Sample.csv_2016-05-19_15-00-15.xml')

        #log.info(infile)
        try:
            ## get root element from xml response file
            qcm_root = qcmr.parse(infile, verbosity)

            ## get the QCMitt response object
            response = qcm_root.get_QCMittResponse()

            ## iterate and extract data from child nodes

            for tRes in response.get_Response():

                ## response status could be one of "Success, Failure, Created"
                if tRes.get_Status() == 'Failure':
                    log.info('either patient or surgical profile bad')
                    log.error( '%s %s %s' % (tRes.get_LCN(), tRes.get_MRN(), tRes.get_Type()) )
                elif tRes.get_Status() == 'Created':
                    log.info('patient, surgical profile created, but others failed')
                    log.info('%s %s %s' % (tRes.get_LCN(), tRes.get_MRN(), tRes.get_Type()))
                elif tRes.get_Status() == 'Success':
                    log.info('patient, surgical profile created, other tables ok')
                    log.info('%s %s %s %s %s' % (tRes.get_LCN(), tRes.get_MRN(), tRes.get_QCM_Casenumber(), tRes.get_Status(), tRes.get_Type()) )
                else:
                    log.warn('unknown status %s' % tRes.get_Status())

        except Exception, errmsg:
            log.error(errmsg)

