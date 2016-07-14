#!/usr/bin/env python

#
# Generated Thu May 26 15:22:31 2016 by generateDS.py version 2.22a.
#
# Command line options:
#   ('-f', '')
#   ('-o', 'qcm_api.py')
#   ('-s', 'qcm_sub.py')
#   ('--super', 'qcm_api')
#   ('--export', 'write etree')
#   ('--member-specs', 'dict')
#
# Command line arguments:
#   ../interface/QCMitt_Response.xsd
#
# Command line:
#   /usr/local/bin/generateDS.py -f -o "qcm_api.py" -s "qcm_sub.py" --super="qcm_api" --export="write etree" --member-specs="dict" ../interface/QCMitt_Response.xsd
#
# Current working directory (os.getcwd()):
#   src
#

import sys
from lxml import etree as etree_

import qcm_api as supermod

def parsexml_(infile, parser=None, **kwargs):
    if parser is None:
        # Use the lxml ElementTree compatible parser so that, e.g.,
        #   we ignore comments.
        parser = etree_.ETCompatXMLParser()
    doc = etree_.parse(infile, parser=parser, **kwargs)
    return doc

#
# Globals
#

ExternalEncoding = 'ascii'

#
# Data representation classes
#


class QCMittSub(supermod.QCMitt):
    def __init__(self, QCMittResponse=None):
        super(QCMittSub, self).__init__(QCMittResponse, )
supermod.QCMitt.subclass = QCMittSub
# end class QCMittSub


class QCMittResponseTypeSub(supermod.QCMittResponseType):
    def __init__(self, Site=None, Response=None):
        super(QCMittResponseTypeSub, self).__init__(Site, Response, )
supermod.QCMittResponseType.subclass = QCMittResponseTypeSub
# end class QCMittResponseTypeSub


class ResponseTypeSub(supermod.ResponseType):
    def __init__(self, Status=None, Type=None, LCN=None, MRN=None, QCM_Casenumber=None, valueOf_=None):
        super(ResponseTypeSub, self).__init__(Status, Type, LCN, MRN, QCM_Casenumber, valueOf_, )
supermod.ResponseType.subclass = ResponseTypeSub
# end class ResponseTypeSub


def get_root_tag(node):
    tag = supermod.Tag_pattern_.match(node.tag).groups()[-1]
    rootClass = None
    rootClass = supermod.GDSClassesMapping.get(tag)
    if rootClass is None and hasattr(supermod, tag):
        rootClass = getattr(supermod, tag)
    return tag, rootClass


def parse(inFilename, silence=False):
    parser = None
    doc = parsexml_(inFilename, parser)
    rootNode = doc.getroot()
    rootTag, rootClass = get_root_tag(rootNode)
    if rootClass is None:
        rootTag = 'QCMitt'
        rootClass = supermod.QCMitt
    rootObj = rootClass.factory()
    rootObj.build(rootNode)
    # Enable Python to collect the space used by the DOM.
    doc = None
    if not silence:
        sys.stdout.write('<?xml version="1.0" ?>\n')
        rootObj.export(
            sys.stdout, 0, name_=rootTag,
            namespacedef_='',
            pretty_print=True)
    return rootObj


def parseEtree(inFilename, silence=False):
    parser = None
    doc = parsexml_(inFilename, parser)
    rootNode = doc.getroot()
    rootTag, rootClass = get_root_tag(rootNode)
    if rootClass is None:
        rootTag = 'QCMitt'
        rootClass = supermod.QCMitt
    rootObj = rootClass.factory()
    rootObj.build(rootNode)
    # Enable Python to collect the space used by the DOM.
    doc = None
    mapping = {}
    rootElement = rootObj.to_etree(None, name_=rootTag, mapping_=mapping)
    reverse_mapping = rootObj.gds_reverse_node_mapping(mapping)
    if not silence:
        content = etree_.tostring(
            rootElement, pretty_print=True,
            xml_declaration=True, encoding="utf-8")
        sys.stdout.write(content)
        sys.stdout.write('\n')
    return rootObj, rootElement, mapping, reverse_mapping


def parseString(inString, silence=False):
    from StringIO import StringIO
    parser = None
    doc = parsexml_(StringIO(inString), parser)
    rootNode = doc.getroot()
    rootTag, rootClass = get_root_tag(rootNode)
    if rootClass is None:
        rootTag = 'QCMitt'
        rootClass = supermod.QCMitt
    rootObj = rootClass.factory()
    rootObj.build(rootNode)
    # Enable Python to collect the space used by the DOM.
    doc = None
    if not silence:
        sys.stdout.write('<?xml version="1.0" ?>\n')
        rootObj.export(
            sys.stdout, 0, name_=rootTag,
            namespacedef_='')
    return rootObj


def parseLiteral(inFilename, silence=False):
    parser = None
    doc = parsexml_(inFilename, parser)
    rootNode = doc.getroot()
    rootTag, rootClass = get_root_tag(rootNode)
    if rootClass is None:
        rootTag = 'QCMitt'
        rootClass = supermod.QCMitt
    rootObj = rootClass.factory()
    rootObj.build(rootNode)
    # Enable Python to collect the space used by the DOM.
    doc = None
    if not silence:
        sys.stdout.write('#from qcm_api import *\n\n')
        sys.stdout.write('import qcm_api as model_\n\n')
        sys.stdout.write('rootObj = model_.rootClass(\n')
        rootObj.exportLiteral(sys.stdout, 0, name_=rootTag)
        sys.stdout.write(')\n')
    return rootObj


USAGE_TEXT = """
Usage: python ???.py <infilename>
"""


def usage():
    print(USAGE_TEXT)
    sys.exit(1)


def main():
    args = sys.argv[1:]
    if len(args) != 1:
        usage()
    infilename = args[0]
    parse(infilename)


if __name__ == '__main__':
    #import pdb; pdb.set_trace()
    main()
