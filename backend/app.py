from flask import Flask

app = Flask(__name__)

@app.route("/view")
def view():
    return "Hello from backend"

@app.route("/")
def health():
    return "Backend OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
