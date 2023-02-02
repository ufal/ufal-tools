import socket
import time as tm
from flask import Flask, url_for, render_template, jsonify

app = Flask(__name__)

@app.route("/")
@app.route("/index")
def index():
    return render_template("index.html", message="Hello from INDEX flask view")


@app.route("/second")
def second():
    return render_template("index.html", message="Hello from  SECOND flask view")


@app.route("/api/time")
def time():
    return jsonify({"hostname": socket.gethostname(), "timestamp": tm.time()})
