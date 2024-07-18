# Websockets on demo machines

## Summary
In order to run websocket app through _quest_ proxy you and UFAL IT need to do the following steps:

1) Choose a unique name of the app (we use _wsapp1_ below) and choose a virtual machine where it will run (we use _demo_
machine).
2) Ufal IT will update `proxy.conf` and `quest_rewrites.conf` on _quest_ machine and restart/reload apache2 on _quest_
3) Update the `server.py` which will run on the _demo_ machine so the app is `/wsapp1/echo`.
4) Update the `client.py` and set the correct address (`ws://quest.ms.mff.cuni.cz/demo/wsapp1/echo`) matching the _demo_
machine name wsapp app name and echo etry point.

Note: Only step 2 is done by IT@UFAL.

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

### Running the user role on custom port
The advantage is that one can have multiple apps per machine

TODO (NOT tested) because there is no apache2 or nginx service running on demo machine yet

```
gunicorn -w 1 --threads 10 server:app --bind 10.10.51.123:9999
```

```
# rules of websocket connection of wsapp1 app
<Location /wsapp1/ >
ProxyPass ws://demo/wsapp1/
ProxyPassReverse ws://demo/wsapp1/
</Location>
```

## Client websocket app setup

```
# Running on client machine e.g. your notebook
# modify the client.py public_internet_address to
# public_internet_address = 'ws://quest.ms.mff.cuni.cz/demo/wsapp1/echo'
# and run:
python client.py public_internet
```

## Contact
Jindra Vodrazka setup or Ondrej Platek for user experience
