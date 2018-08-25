import os
import sys
from flask import Flask
from flask_restful import Resource, Api


__author__='Shafin Thiyam'

class xml_processsing():

    def __init__(self,xsl,input_xml):
        self.xsl=xsl
        self.input_xml=input_xml

    def tranformation(self):
        if self.input_xml.endswith('txt'):
            input_list = open(self.input_xml).read().split("\n")
            for i in input_list:
                print("Transforming {} to {}_output.xml".format(i,self.xsl,i.split('.')[0]))
                os.system("java net.sf.saxon.Transform -s:{0} -xsl:{1} -o:{2}_output.xml".format(i,self.xsl,i.split('.')[0]))
            #os.system("java net.sf.saxon.Transform -s:{0} -xsl:{1} -o:{2}_output.xml".format(i,self.xsl,i.split('.')[0]) for i in input_list)
        else:
            print("Transforming {} to {}_output.xml".format(self.input_xml,self.xsl,self.input_xml.split('.')[0]))
            os.system("java net.sf.saxon.Transform -s:{0} -xsl:{1} -o:{2}_output.xml".format(self.input_xml,self.xsl,self.input_xml.split('.')[0]))

if __name__=='__main__':
    if len(sys.argv) == 3:
        print("processing started...")
        xsl= sys.argv[1]
        inputs=sys.argv[2]
        outputs=sys.argv[3]
        transform=xml_processsing(xsl,inputs,outputs)
        transform.tranformation()
        print("Transformation Done")
    else:
        print ('Three inputs required - {Stylesheet} {input_file} {output_file}')
        exit()
