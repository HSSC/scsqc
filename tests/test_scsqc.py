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
        log = logger.logInit('INFO', logf, 'test', 2);

        ## check logfile was created
        self.assertEqual(os.path.exists(logf), True);
        if log:
            log.info('this is an info line')
            log.error('this is an error line')

        self.assertEqual(os.stat(logf).st_size, 104)
        os.remove(logf)

    ## unit test for config
    def test_sqcbase_config(self):
        from sqcbase import config

        inpf = 'config_test.csv'
        comp = [ {'var1a': 'value1A', 'var2a': 'value2A'}, {'var2b': 'value2B'} ]
        secs = ['sectionA', 'sectionB']

        ## create an ini file to parse
        with open(inpf, 'w') as f:
            f.write('\n;comment A\n[sectionA]\nvar1A: value1A\nvar2A: value2A\n\n[sectionB]\nvar2B: value2B\n\n')
            f.close()

        ## parse ini file using module and compare sections, vars
        cfg_parse = config.getConfigParser(inpf)
        self.assertEqual(cfg_parse.sections(), secs)
        rep = []
        for item in cfg_parse.sections():
            rep.append( config.getConfigSectionMap(cfg_parse, item) )
        self.assertEqual(rep, comp)

        comp = [{'col2': 'b', 'col3': 'c', 'col1': 'a'}, {'col2': 'e', 'col3': 'f', 'col1': 'd'}, {'col2': 'h', 'col3': 'i', 'col1': 'g'}]
        with open(inpf, 'w') as f:
            f.write('#this is a comment\n\ncol1,col2,col3\na, b, c\nd, e, f\ng, h, i\n')
            f.close()
        data = config.parseCSV(inpf)
        self.assertEqual(data, comp)
        os.remove(inpf)

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
        log = logger.logInit('INFO')
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

    def test_transfer_sftp_aput(self):

        from transfer import sftp_transfer
        host='hssc-cdwr3-hsie-d.clemson.edu'
        port=22
        usern='transfer'
        keyfile= os.path.join(os.getcwd(), 'roles/pyenv/files/hsie-d.key')
        filename = 'BigFILE'
        filepath = os.path.join(os.getcwd(), filename)
        os.system('dd if=/dev/zero of=%s bs=40960 count=1 iflag=fullblock status=none' % filepath)
        handle, transport = sftp_transfer.sftp_connect(host, port, usern, keyfile)
        if not hasattr(self, 'assertIsNotNone'):
            self.assertNotEqual(handle, None)
        else:
            self.assertIsNotNone(handle)
        sftp_transfer.sftp_put(handle, filename, ('/home/%s/testing/large/file/%s' % (usern, filename) ))
        os.remove(filepath)
        transport.close()

    def test_transfer_sftp_bget(self):

        from transfer import sftp_transfer
        host='hssc-cdwr3-hsie-d.clemson.edu'
        port=22
        usern='transfer'
        keyfile= os.path.join(os.getcwd(), 'roles/pyenv/files/hsie-d.key')
        filename = 'BigFILE'
        filepath = '/home/%s/testing/large/file/%s' % (usern, filename)
        handle, transport = sftp_transfer.sftp_connect(host, port, usern, keyfile)
        if not hasattr(self, 'assertIsNotNone'):
            self.assertNotEqual(handle, None)
        else:
            self.assertIsNotNone(handle)
        sftp_transfer.sftp_get(handle, filepath , filename.lower())
        os.remove(filename.lower())
        transport.close()


if __name__ == '__main__':
    unittest.main(failfast=True, exit=False)
