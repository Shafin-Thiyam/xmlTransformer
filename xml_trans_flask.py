import os
import sys
from datetime import datetime
import shutil
import json
import random
import sys ,requests
from flask import Flask,request,make_response,jsonify
from werkzeug.utils import secure_filename
from xmlTransformer import xmlTransformer

app =Flask(__name__,instance_relative_config=True)
url="/transform"
@app.route(url,methods=['POST'])
def transform():
    xsl = request.files['xsl_file']
    input_xml = request.files['input_file']
    dir_path = os.path.dirname(__file__)
    out_data = {}

    if xsl!='' and input_xml!='':
        work_dir = os.path.join(dir_path, '__work__', datetime.now().strftime("%Y%m%d%H%M%S%f") + "_" + random.choice('ABCDEFGHIJKL') )
        if not os.path.exists(work_dir):
            os.makedirs(work_dir)

        input_file_path = "{path}/{file}".format(path=work_dir, file=input_xml.filename).replace('/', '\\')
        xsl_file_path = "{path}/{file}".format(path=work_dir, file=xsl.filename).replace('/', '\\')
        input_xml.save(input_file_path)
        xsl.save(xsl_file_path)
        output_file = (work_dir+"/output_"+input_xml.filename).replace('/', '\\')
        transform=xmlTransformer(xsl_file_path,input_file_path,output_file)
        transform.tranformation()
        f = open(output_file, "r", encoding="utf8")
        out_data["content"] = f.read().rstrip("\n")
        f.close()
        if os.path.exists(work_dir):
            shutil.rmtree(work_dir)
        return out_data["content"].encode('utf-8')
    else:
       return "<p>invalid input</p>"



@app.errorhandler(404)
def NotFound(error):
    return 'Not Found,The specified resource could not be found', 404


@app.errorhandler(400)
def NotFound(error):
    return 'Mandatory field are missing', 400


@app.errorhandler(405)
def MethodNotAllowed(error):
    return 'Method Not Allowed,Your request used an invalid method', 405


@app.errorhandler(429)
def TooManyRequests(error):
    return 'Too Many Requests,You have reached the rate-limit', 429


@app.errorhandler(500)
def InternalServerError(error):
    return 'Provide the required parameter to the payload!', 500


@app.errorhandler(503)
def ServiceUnavailable(error):
    return 'Service Unavailable,We are temporarily offline for maintenance', 503

if __name__ == '__main__':
    app.run(port='1323', debug=True)
