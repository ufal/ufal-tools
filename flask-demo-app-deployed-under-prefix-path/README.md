# Running Flask under subpath/URL prefix at domain

At UFAL we run demo projects URLs with a template `http://DOMAIN/MACHINE_NAME/YOUR_APP_NAME`
e.g. http://quest.ms.mff.cuni.cz/rel2text/tabgenie.

From a developer perspective it means that:
- There is a single Apache Proxy which routes the requests to different machines and you cannot influence at all.
- There is an Apache Proxy server which receives requests that route your application from a URL prefix to localhost using 
  a port which does not require sudo e.g. port 5000.
- **From a Flask developer perspective, it means that URLs links do NOT work out of the box. The prefix `/rel2text/tabgenie` is needed: `<a href="/rel2text/tabgenie/XY">Show XY</a>` instead of `<a href="/XY"> Show XY</a>`**


Luckily, URL prefix deployment could be automated using Flask using correct reverse proxy setup (in Apache), wsgi handling
and using recommended practices in Flask.

## Apache Setup on the deployment machine
It is important to re-add the stripped URL prefix back to the address.
```
# This configuration belongs to Apache Server running on the rel2text machine.
# rel2text URL prefix was stripped on the first Apache proxy delegating traffic to different machines.

ProxyPass /tabgenie http://127.0.0.1:5000/rel2text/tabgenie
ProxyPassReverse /tabgenie http://127.0.0.1:5000/rel2text/tabgenie
```

## WSGI compatible deployment
The SCRIPT_NAME variable is responsible for informing the wsgi application about the URL prefix.

```
cd src  
# production deployment
SCRIPT_NAME=/rel2text/tabgenie gunicorn app:app --bind 127.0.0.1:5000

# 
# WARNING THIS DOES NOT WORK -- use e.g. ngrok for local development on quest 
# Flast development server ignores SCRIPT_NAME
# FLASK_APP=app SCRIPT_NAME=/rel2text/tabgenie flask run
```

## Flask automatic URL creation

Use `url_for` everywhere for correct URL prefixing.
Among other places it is important to use it at:
- In templates fore views `<h1><a href="{{ url_for('index') }}" >Link to INDEX view</a></h1>`
- linking static files - static folder is automatically registered static view in Flask:   `<link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">`
- Etc.


## Installation
Recommended installation and deployment is:
```
python3 -m venv venv && \
  source venv/bin/activate && \
  pip install -r requirements.txt && \
  cd src && \
  SCRIPT_NAME=/rel2text/tabgenie gunicorn app:app --bind 127.0.0.1:5000
```


### References
- [1] https://dlukes.github.io/flask-wsgi-url-prefix.html


Note2: This minimal application was tested on namuddis machine on demo which is not ready to receive public attention :).
