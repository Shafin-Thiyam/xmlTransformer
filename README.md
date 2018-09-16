## xmlTransformer
**Installation:**
```
flask, flask_resful, saxon parser 9 or later.
```
**Description:** 
```
Purpose of the project to run given style sheet on any given xml file generate xml output in json format.
```
*Implementation:** 
```
curl --request POST \
  --url http://<qualified name of the machine>:1323/v1/xmlTransformer \
  --header 'Cache-Control: no-cache' \
  --header 'Content-Type: application/json' \
  --header 'Postman-Token: 530312e1-b6b5-4dc0-8f7d-16c12591cd6d' \
  --header 'content-type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' \
  --form xsl_file=<xsl files> \
  --form input_file=<xml file>
```
