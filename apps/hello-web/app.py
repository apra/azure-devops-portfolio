import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    # Demonstration only: the value is a harmless test string held in Key Vault.
    # A real application would never return a secret to the caller.
    return jsonify(message=os.environ.get("DEMO_MESSAGE", "DEMO_MESSAGE is not set"))


@app.get("/healthz")
def healthz():
    return jsonify(status="ok")