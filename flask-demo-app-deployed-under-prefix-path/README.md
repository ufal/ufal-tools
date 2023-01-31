# Running Flask under subpath at domain

At UFAL we run a demo projects URLs with this template http://DOMAIN/MACHINE_NAME/YOUR_APP_NAME 
e.g. http://quest.ms.mff.cuni.cz/rel2text/tabgenie.

From a developer perspective it means that:
- There is a single Apache Proxy which routes the requests to different machines and you cannot influence at all.
- There is an Apache Proxy server which receives requests which routes your application from a subpath to localhost and
  ports which do not require sudo e.g. 5000.
- **From a Flask developer it means that URLs links do NOT work out of the box. The prefix `/rel2text/tabgenie` is needed: `<a href="/rel2text/tabgenie/XY">Show XY</a>` instead of `<a href="/XY"> Show XY</a>`


Luckily, subpath deployment could be automated using Flask using correct reverse proxy setup (in Apache), wsgi handling
and using recommended practices in Flask.

## Apache Setup on the deployment machine
It is important to re-add the stripped subpath back to the address.
```
# This configuration belongs to Apache Server running on the rel2text machine.
# rel2text subpath was stripped on the first Apache proxy delegating traffic to different machines.

ProxyPass /tabgenie http://127.0.0.1:5000/rel2text/tabgenie
ProxyPassReverse /tabgenie http://127.0.0.1:5000/rel2text/tabgenie
```

## WSGI compatible deployment
The SCRIPT_NAME variable is responsible for informing the wsgi application about the subpath.

```
cd src  
# production deployment
SCRIPT_NAME=/rel2text/tabgenie gunicorn app:app --bind 127.0.0.1:5000
# Flask development server by defaults run on 127.0.0.1 and port 5000
FLASK_APP=app SCRIPT_NAME=/rel2text/tabgenie flask run
```

## Flask automatic URL creation

Use `url_for` everywhere for correct URL prefixing.
Among other places it is important to use it at:
- In templates fore views `<h1><a href="{{ url_for('index') }}" >Link to INDEX view</a></h1>`
- linking static files - static folder is automatically registered static view in Flask:   `<link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">`
- Etc.


## Installation
Recommended installation and deployment
```
python3 -m venv venv && \
  source venv/bin/activate && \
  pip install -r requirements.txt && \
  cd src && \
  SCRIPT_NAME=/rel2text/tabgenie gunicorn app:app --bind 127.0.0.1:5000
```


### References
- https://dlukes.github.io/flask-wsgi-url-prefix.html


Note2: This minimal application was tested on namuddis machine on demo which is not ready to receive public attention :).
