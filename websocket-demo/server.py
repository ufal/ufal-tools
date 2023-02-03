from flask import Flask, render_template, request
import logging
import simple_websocket
app = Flask(__name__)


@app.route('/echo', websocket=True)
def echo():
    ws = simple_websocket.Server(request.environ)
    try:
        while True:
            data = ws.receive()
            print(f"Received: {data}")
            ws.send(f"data from server {data}")
    except simple_websocket.ConnectionClosed:
        logging.warning(f"connection closed")
    return ''
