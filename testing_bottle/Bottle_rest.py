import os
import shutil
from bottle import route, request, static_file, run
import os
from bottle import route, request, static_file, run

@route('/')
def root():
    return static_file('test.html', root='.')

@route('/login', method='POST')
def do_upload():
    category = request.forms.get('category')
    upload = request.files.get('upload')
    save_path = "/tmp/{category}".format(category=category)
    file_path = "{path}/{file}".format(path=save_path, file=upload.filename)
    name, ext = os.path.splitext(upload.filename)
    if ext not in ('.txt','.xml', '.xsl', '.xslt'):
        return "File extension not allowed."


    if not os.path.exists(save_path):
        os.makedirs(save_path)


    upload.save(file_path)
    return "File successfully saved to '{0}'.".format(save_path)


if __name__ == '__main__':
    run(host='localhost', port=8080)
