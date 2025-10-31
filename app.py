from flask import Flask, jsonify
import boto3, json, os
from botocore.exceptions import ClientError

app = Flask(__name__)

SECRET_NAME = os.getenv("SECRET_NAME", "demo/db_password")
REGION = os.getenv("AWS_REGION", "us-east-1")

@app.route("/")
def home():
    return "Hello from Flask!", 200

@app.route("/healthz")
def health():
    return jsonify({"status": "ok"}), 200

@app.route("/secret")
def secret():
    try:
        sm = boto3.client("secretsmanager", region_name=REGION)
        resp = sm.get_secret_value(SecretId=SECRET_NAME)
        secret = json.loads(resp["SecretString"])
        return jsonify({"password": secret["password"][:2] + "****"}), 200  # mask it for safety
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
