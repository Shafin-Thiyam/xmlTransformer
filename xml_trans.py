import os
import sys
from datetime import datetime
import shutil
import json
import random
import sys
from bottle import route, run, template
from bottle import get, post, request # or route

from xmlTransformer import xmlTransformer

@post('/transform') # or @route('/login', method='POST')
def transform():
    xsl = request.forms.get('xsl')
    input_xml = request.forms.get('input_xml')
    dir_path = os.path.dirname(__file__)
    out_data = {}

    if xsl!='' and input_xml!='':

        work_dir = os.path.join(dir_path, '__work__',datetime.now().strftime("%Y%m%d%H%M%S%f") + "_" + random.choice('ABCDEFGHIJKL'))
        #if not os.path.exists(work_dir):
           # os.makedirs(work_dir)
        output_file=input_xml.split('.')[0]+'_output.xml'

        transform=xmlTransformer(xsl,input_xml,output_file)
        transform.tranformation()
        f = open(output_file, "r", encoding="utf8")
        out_data["content"] = f.read().rstrip("\n")
        f.close()

        return out_data["content"].encode('utf-8')
    else:
        return "<p>Login failed.</p>"


run(host='localhost', port=1323, debug=True)