#!/usr/bin/python3
import web
import os
import sys
from datetime import datetime
import shutil
import json
import consul
import subprocess
import re
import random
import socket
import sys
sys.path.append('src')
from xmlTransformer import xmlTransformer

urls = (
    '/v1/xmlTransformer/(.*)', 'Trans'
)
app = web.application(urls, globals())

if len(sys.argv) > 1:
    try:
        port = int(sys.argv[1])
    except:
        print("Input for Port is invalid.")
        exit()
else:
    print("Port number not provided.\nExample: python rest.py 9999")
    exit()

if len(sys.argv) > 2:
    build = sys.argv[2]
else:
    build = 0

class Trans:

    def POST(self):

        out_data = {}

        x = web.input()
        input_f=x.input_file
        xsl_f=x.xsl_file

        dir_path = os.path.dirname(__file__)

        if input_f!='' and xsl_f!='':

            work_dir = os.path.join(dir_path, '__work__', datetime.now().strftime("%Y%m%d%H%M%S%f") + "_" + random.choice('ABCDEFGHIJKL') )
            if not os.path.exists(work_dir):
                os.makedirs(work_dir)

            #file_path = input_f.filename.replace('\\', '/')  # replaces the windows-style slashes with linux ones.
            #xsl_file_path = xsl_f.filename.replace('\\', '/')  # replaces the windows-style slashes with linux ones.
            file_name = input_f.split('\\')[-1]
            xsl_file_name = xsl_f.split('\\')[-1]
            input_file = os.path.join(work_dir, file_name)
            xsl_file = os.path.join(work_dir, xsl_file_name)
            with open(input_file, 'wb') as saved:
                shutil.copyfileobj(x['input_file'].file, saved)
            with open(xsl_file, 'wb') as saved:
                shutil.copyfileobj(x['xsl_file'].file, saved)

            output_file = os.path.join(work_dir, "out_" + file_name)

            # python = sys.executable
            # at_cmd = python + " src/Autotagger.py " + publication + " " + input_file + " " + output_file + " xml"
            # print("AutoTagger : " + at_cmd + "\n")
            # os.system(at_cmd)
            transfomer = xmlTransformer(xsl_file,input_file,output_file)
            transfomer.tranformation()

            f = open(output_file, "r", encoding="utf8")
            out_data["content"] = f.read().rstrip("\n")
            f.close()

            if os.path.exists(work_dir):
                shutil.rmtree(work_dir)

            return out_data["content"].encode('utf-8')

def register():
    fqdn = socket.getfqdn()
    print("\n-- autotagger service register started")
    c = consul.Consul()

    # a HTTP GET against url every 10s for health check
    check = consul.Check.http("http://localhost:%d/health" % port, "30s")

    c.agent.service.register("autotagger", "autotagger",
                             check=check,address=fqdn,port=port,
                             tags=['build='+build, "port=%d" % port])

    # index, nodes = c.health.service('autotagger') #
    print("services: " + str(c.agent.services()))


def unregister():
    print("\n-- autotagger service unregister started")
    c = consul.Consul()
    c.agent.service.deregister("autotagger")
    print("services: " + str(c.agent.services()))


def get_build():
    version = str((subprocess.check_output(['git', 'describe'])).decode("utf-8").rstrip())

    build = version.replace("TRTA-ContentTechnology-autotagger-", "")
    build = re.sub('\-[a-z0-9\-]*', '', build)

    return build

if __name__ == "__main__":
    #register()
    app.run(host='127.0.0.1')
    # unregister()

