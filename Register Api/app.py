from flask import Flask,request,make_response,jsonify
import os
##import cx_Oracle
app = Flask(__name__, instance_relative_config=True)
url= '/transform'
@app.route('/')
def index():
    return 'INDEX'


@app.route(url,methods=['POST'])
def checkpointextract():
    return 'Running'


##@app.route(document,method=['POST'])
##@app.route('/')
##def document():
##    if request.method == 'POST':
##        connection = cx_Oracle.connect("ria_web/ria_web@cps_service.int.thomsonreuters.com")
##        cursor = connection.cursor()
##        cursor.execute("SELECT * FROM Export_Classifier_Docs")
##        count = cursor.fetchall()
##        return count
##    ##return 'INDEX'

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
    app.run(host='0.0.0.0', port='5550')

