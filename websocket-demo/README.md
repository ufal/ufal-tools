# Websockets on demo machines

## Summary
In order to run websocket app through _quest_ proxy you and UFAL IT need to do the following steps:

1) Choose a unique name of the app (we use _wsapp1_ below) and choose a virtual machine where it will run (we use _demo_
machine).
2) Ufal IT will update `proxy.conf` and `quest_rewrites.conf` on _quest_ machine and restart/reload apache2 on _quest_
3) Update the `server.py` which will run on the _demo_ machine so the app is `/wsapp1/echo`.
4) Update the `client.py` and set the correct address (`ws://quest.ms.mff.cuni.cz/demo/wsapp1/echo`) matching the _demo_
machine name wsapp app name and echo etry point.

Note1: Only step 2 is done by IT@UFAL.

Note2: For both, the client and server you need to install dependencies:
- Create Python 3 virtual environment `python3 -m venv venv` and activate it for your shell `source ./venv/bin/activate`.
- Install requirements `pip install -r requirements.txt`

## Guest machine setup

```
# Quest machine
#/etc/apache2/mods-enabled/proxy.conf:
# apache2 URL and headers rewrite rules for http and port 80 of the virtual machine "demo"a available at https://quest.ms.ufal.mff.cuni.cz/demo/
<Location /demo/>
ProxyPass http://demo/
ProxyPassReverse http://demo/
ProxyPassReverseCookieDomain  demo quest.ms.mff.cuni.cz
ProxyPassReverseCookiePath  /  /demo/
</Location>
```

```
# Quest machine
# /etc/apache2/quest_rewrites.conf:

RewriteRule ^/wsapp1$ /demo/wsapp1/ [R]
RewriteRule ^/demo/wsapp1$ /demo/wsapp1/ [R]
RewriteCond %{HTTP:Upgrade} ^websocket$ [NC]
RewriteCond %{HTTP:Connection} ^upgrade$ [NC]
RewriteRule ^/?demo/wsapp1/(.*) ws://demo/wsapp1/$1 [P,L]

RewriteRule ^/demo$ /demo/ [R]
```

## Demo machine setup
```
# setup of server.py on guest machine
# change the server address to following
@app.route('/wsapp1/echo', websocket=True)
def echo():
   ...
```


### Run with superuser  role on port 80

```
## Running the server in the on demo machine from the ufal-tools/websocket-demo dir
# without proxypass rules at apache
#
# the good thing is that it works 
# the bad thing it runs on port 80 and IT REQUIRES superuser login
# logged in as su
gunicorn -w 1 --threads 10 server:app --bind $(ip addr show
eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1):80
```

### Running the user role on a custom port
The advantage is that one can have multiple apps per machine.
However, IT UFAL needs to use rewrite rule to quest with the port for each machine. 
E.g. rule like this

```
# Rewrite rulle for wsapp1
RewriteRule ^/?demo/wsapp1/(.*) ws://demo:8080/wsapp1/$1 [P,L]
```
Then you can run the wsapp1 from server.py without sudo on custom port `8080`:

```
gunicorn -w 1 --threads 10 server:app --bind 10.10.51.123:8080
```

## Client websocket app setup

```
# Running on client machine e.g. your notebook
# modify the client.py public_internet_address to
# public_internet_address = 'ws://quest.ms.mff.cuni.cz/demo/wsapp1/echo'
# and run:
python client.py public_internet
```

## Note on gunicorn
#!/bin/bash
# # Section in the `/etc/nginx/sites-available/default`
# #
#     # petbot
#     # note also that petbot should accept websocket connection
#     # at wsapp1/ollama locally for request addressed by client as quest.mff.cuni.cz/demo/wsapp1/ollama
#     # which is handled by quest itself using this rewrite rule
#     #
#     # # Rewrite rulle for wsapp1
#     # RewriteRule ^/?demo/wsapp1/(.*) ws://demo:8080/wsapp1/$1 [P,L]
#     #
#     # See https://github.com/ufal/ufal-tools/tree/master/websocket-demo#running-the-user-role-on-a-custom-port
#     #
#     # Conclusion the http should be served at the same port -> 8080
#     rewrite ^/petbot/(.*)/$ /demo/petbot/$1 permanent;
#     location /petbot {
#         proxy_pass http://localhost:8080/;
#     }
#     location /petbot/ {
#         proxy_pass http://localhost:8080/;
#     }
#     # end of petbot
export FLASK_RUN_PORT=8080;
# more than two workers might be problematic if your app is not "thread/process" save. Empiricaly proven problematic when reading and writing to the same files.
gunicorn -w 1 --threads 10 'petbot.bin.serve:create_app()' --bind 0.0.0.0:8080

## Contact
Jindra Vodrazka setup or Ondrej Platek for user experience
