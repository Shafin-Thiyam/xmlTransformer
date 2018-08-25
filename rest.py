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
from xmlTransformer import xml_processsing

urls = (
    '/health', 'Health',
    '/xmltransformer/(.*)', 'Trans'
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


class Health:
    def GET(self):
        return '{"description":"Python xmltransformer","status":"UP"}'



class Trans:
    def POST(self,xsl):
        out_data={}
        x=web.input(input_file={})

        dir_path = os.path.dirname(__file__)

        if 'input_file' in x:

            work_dir = os.path.join(dir_path, '__work__', datetime.now().strftime("%Y%m%d%H%M%S%f") + "_" + random.choice('ABCDEFGHIJKL') )
            if not os.path.exists(work_dir):
                os.makedirs(work_dir)

            file_path = x.input_file.filename.replace('\\', '/')  # replaces the windows-style slashes with linux ones.
            file_name = file_path.split('/')[-1]
            input_file = os.path.join(work_dir, file_name)
            with open(input_file, 'wb') as saved:
                shutil.copyfileobj(x['input_file'].file, saved)

            output_file = os.path.join(work_dir, "out_" + file_name)

            xml_pro=xml_processsing(xsl,input_file,output_file)

            xml_pro.tranformation()

            f = open(output_file, "r", encoding="utf8")
            out_data["content"] = f.read().rstrip("\n")
            f.close()

def register():
    fqdn = socket.getfqdn()
    print("\n-- xmltransformer service register started")
    c = consul.Consul()

    # a HTTP GET against url every 10s for health check
    check = consul.Check.http("http://localhost:%d/health" % port, "30s")

    c.agent.service.register("xmltransformer", "xmltransformer",
                             check=check,address=fqdn,port=port,
                             tags=["port=%d" % port])

    # index, nodes = c.health.service('autotagger') #
    print("services: " + str(c.agent.services()))


def unregister():
    print("\n-- xmltransformer service unregister started")
    c = consul.Consul()
    c.agent.service.deregister("xmltransformer")
    print("services: " + str(c.agent.services()))


def get_build():
    version = str((subprocess.check_output(['git', 'describe'])).decode("utf-8").rstrip())

    build = version.replace("TRTA-ContentTechnology-xmltransformer-", "")
    build = re.sub('\-[a-z0-9\-]*', '', build)

    return build

if __name__ == "__main__":
    register()
    app.run()
    # unregister()
