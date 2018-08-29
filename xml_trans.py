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
    #xsl = request.forms.get('xsl_file')
    xsl = request.files.get('xsl_file')
    #input_xml = request.forms.get('input_xml')
    input_xml = request.files.get('input_file')
    dir_path = os.path.dirname(__file__)
    out_data = {}

    if xsl!='' and input_xml!='':

        work_dir = os.path.join(dir_path, '__work__', datetime.now().strftime("%Y%m%d%H%M%S%f") + "_" + random.choice('ABCDEFGHIJKL') )
        if not os.path.exists(work_dir):
            os.makedirs(work_dir)
        #input_file_path = os.path.join(work_dir, input_xml.filename)
        input_file_path = "{path}/{file}".format(path=work_dir, file=input_xml.filename).replace('/', '\\')
        input_xml.save(input_file_path)
        #xsl_file_path=os.path.join(work_dir,xsl.filename)
        xsl_file_path = "{path}/{file}".format(path=work_dir, file=xsl.filename).replace('/', '\\')
        xsl.save(xsl_file_path)
        #output_file=os.path.join(work_dir,'output_'+input_xml.filename)
        output_file = (work_dir+"/output_"+input_xml.filename).replace('/', '\\')

        transform=xmlTransformer(xsl_file_path,input_file_path,output_file)
        transform.tranformation()
        f = open(output_file, "r", encoding="utf8")
        out_data["content"] = f.read().rstrip("\n")
        f.close()
        if os.path.exists(work_dir):
            shutil.rmtree(work_dir)

        return out_data["content"].encode('utf-8')
        #return out_data["content"]
    else:
        return "<p>invalid input</p>"


run(host='localhost', port=1323, debug=True)

#run(port=1323, debug=True)
