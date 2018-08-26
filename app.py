from flask import Flask, request
from flask_restful import Api, Resource
import xmlTransformer

app=Flask(__name__)
api=Api(app)

api.add_resource(xmlTransformer.xml_processsing)