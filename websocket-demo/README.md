# Websocket demo

## Installation

1. Ssh to `quest.ms.mff.cuni.cz` and to `namuddis`
2. Create Python 3 virtual environment `python3 -m venv venv` and activate it for your shell `source ./venv/bin/activate`.
3. Install requirements `pip install -r requirements.txt`

## Testing
Please, install requirements before testing.

### Local deployment and testing
Open two terminals on `namuddis` and test that local websocket connections work fine.

```
# terminal 1 on namuddis
$ source venv/bin/activate
$ gunicorn -w 1 --threads 10 server:app --bind 127.0.0.1:9999

... You should see  output like this after startup ...
[2023-02-03 10:45:00 +0100] [23917] [INFO] Starting gunicorn 20.1.0
[2023-02-03 10:45:00 +0100] [23917] [INFO] Listening at: http://127.0.0.1:9999 (23917)
[2023-02-03 10:45:00 +0100] [23917] [INFO] Using worker: gthread
[2023-02-03 10:45:00 +0100] [23918] [INFO] Booting worker with pid: 23918
... no more output before starting the client in the second terminal ...
... once you have started the client you should see similar output...
Received: 1675418171.2838495
Received: 1675418171.384584
Received: 1675418171.4855952
Received: 1675418171.5864708
Received: 1675418171.6871643
...

```

```
# terminal 2 on namuddis
# Start the server on terminal 1 first
$ source venv/bin/activate
$ python client.py local
> 1675418171.2838495
< data from server 1675418171.2838495
> 1675418171.384584
< data from server 1675418171.384584
> 1675418171.4855952
< data from server 1675418171.4855952
> 1675418171.5864708
< data from server 1675418171.5864708
> 1675418171.6871643
< data from server 1675418171.6871643
```

### Test the server on namuddis but the client on a notebook connecting from public Internet
Open two terminals. The terminal with server on namuddis is deployed exactly the same as for local deployment.
The second terminal with the client should be at your local machine connecting from public internet.
The client is trying to connect to  `ws://quest.ms.mff.cuni.cz/namuddis/ws-test/echo`

Note: in order the client to work, perform the same installation as you did on `namuddis`.
```
# terminal 2 on your notebook connecting from PUBLIC internet network
# Start the server on terminal 1 first
$ source venv/bin/activate
$ python client.py public_internet
... currently not working....
```
