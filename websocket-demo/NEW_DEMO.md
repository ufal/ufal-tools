# Websockets on demo machines

# Summary
Rozbehnuti WS aplikace za proxy skrze quest znamena:

1) vybrat unikatni jmeno (neco jako "wsapp1") a vybrat virtualku kde pobezi (v priklady vyse "demo")
2) pridat odpovidajici konfiguraci do proxy.conf a do quest_rewrites.conf na questu a provest reload/restart apache
3) v serverove casti nastavit spravne app.route. Jde vlastne o URL bez nazvu virtualky.
4) v klientske casti nastavit adresu "ws://quest.ms.mff.cuni.cz/demo/wsapp1/echo" (predpokladam ze "echo" je entry point definovany v serverove casti)

Pouze krok 2 musi udelat nekdo z it@ufal.

Zkusim sem popsat celou relevantni konfiguraci, kterou muzeme podle potreby replikovat na dalsi WS projekty.
Pouzivam "wsapp1" jako oznaceni aplikace a "demo" je nazev virtualky.

## Guest machine setup

```
# Quest machine
#/etc/apache2/mods-enabled/proxy.conf:
# pravidla pro http - port 80 z virtualky demo je pristupny na https://quest.ms.ufal.mff.cuni.cz/demo/
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
# pravidla pro websocketove spojeni aplikace wsapp1
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

