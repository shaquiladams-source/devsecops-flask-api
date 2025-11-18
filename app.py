from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Flask (local)!", 200

@app.route("/healthz")
def health():
    return jsonify({"status": "ok"}), 200

@app.route("/version")
def version():
    # CI/CD will eventually inject this env var
    git_sha = os.getenv("GIT_SHA", "local-dev")
    return jsonify({"version": git_sha}), 200

if __name__ == "__main__":
    # run on 0.0.0.0 so Docker can reach it later
    app.run(host="0.0.0.0", port=8080)
