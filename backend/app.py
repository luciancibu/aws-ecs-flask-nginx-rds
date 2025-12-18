from flask import Flask, request
import pymysql, os

app = Flask(__name__)

def get_conn():
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        connect_timeout=5
    )

def ensure_table():
    conn = get_conn()
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS counter (
                id INT PRIMARY KEY,
                views BIGINT NOT NULL
            )
        """)
        cur.execute("""
            INSERT INTO counter (id, views)
            SELECT 1, 0
            WHERE NOT EXISTS (SELECT 1 FROM counter WHERE id=1)
        """)
        conn.commit()
    finally:
        conn.close()

@app.before_first_request
def init_db():
    ensure_table()

@app.route("/view")
def view_counter():
    conn = get_conn()
    try:
        cur = conn.cursor()
        if request.args.get("read") != "true":
            cur.execute("UPDATE counter SET views = views + 1 WHERE id=1")
            conn.commit()

        cur.execute("SELECT views FROM counter WHERE id=1")
        return str(cur.fetchone()[0])
    finally:
        conn.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
