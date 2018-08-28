from bottle import route, run, template
from bottle import get, post, request # or route

@route('/hello/<name>')
def index(name):
    return template('<b>Hello {{name}}</b>!', name=name)

@post('/login') # or @route('/login', method='POST')
def do_login():
    username = request.forms.get('username')
    password = request.forms.get('password')
    if username=='shafin' and password=='hamna':
        return "Your login information was correct."+username+"</p><p>Your login information was correct."+password+"</p>"
    else:
        return "Login failed."


run(host='localhost', port=8080, debug=True)