
import os
from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST'),
        database=os.environ.get('DB_NAME'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASS')
    )
    return conn

@app.route('/healthz')
def healthz():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        # Execute a simple query to check the database connection
        cur.execute('SELECT 1;')
        cur.close()
        conn.close()
        return jsonify({'status': 'ok', 'database': 'ok'})
    except Exception as e:
        return jsonify({'status': 'error', 'database': 'unhealthy', 'error': str(e)}), 503

@app.route('/api/games')
def get_games():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM games;')
        games = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(games)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
