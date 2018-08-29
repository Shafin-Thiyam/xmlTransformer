import os
import sys
from datetime import datetime
import shutil
import json
import random
import sys,requests
from flask import Flask, render_template, request
from werkzeug.utils import secure_filename
app = Flask(__name__)

@app.route('/uploader', methods = ['POST'])
def upload_file():
    dir_path = os.path.dirname(__file__)
    work_dir = os.path.join(dir_path, '__work__', datetime.now().strftime("%Y%m%d%H%M%S%f") + "_" + random.choice('ABCDEFGHIJKL') )
    if not os.path.exists(work_dir):
        os.makedirs(work_dir)
    f = request.files['file']
    input_file_path = "{path}/{file}".format(path=work_dir, file=f.filename).replace('/', '\\')
    f.save(input_file_path)
    return 'file uploaded successfully '+input_file_path
		
if __name__ == '__main__':
   app.run(debug = True)
