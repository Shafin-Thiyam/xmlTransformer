import os
import sys
from flask import Flask
from flask_restful import Resource, Api


__author__='Shafin Thiyam'

class xmlTransformer(object):

    def __init__(self,xsl,input_xml,output_xml):
        self.xsl=xsl
        self.input_xml=input_xml
        self.output_xml=output_xml

    def tranformation(self):
        print("Transforming {} to {}".format(self.input_xml,self.output_xml))
        os.system("java net.sf.saxon.Transform -s:{0} -xsl:{1} -o:{2}".format(self.input_xml,self.xsl,self.output_xml))
        print("Transformation Done")

if __name__=='__main__':
    if len(sys.argv) == 4:
        print("processing started...")
        xsl= sys.argv[1]
        inputs=sys.argv[2]
        outputs=sys.argv[3]
        transform=xmlTransformer(xsl,inputs,outputs)
        transform.tranformation()
        print("Transformation Done")
    else:
        print ('Three inputs required - {Stylesheet} {input_file} {output_file}')
        exit()
