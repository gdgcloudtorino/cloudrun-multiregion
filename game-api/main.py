
import os
from flask import Flask, jsonify, request
import psycopg2
from pgvector.psycopg2 import register_vector
import google.generativeai as genai

app = Flask(__name__)

# Configure the generative AI model
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
model = genai.get_embedding_model("models/embedding-001")

def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST'),
        database=os.environ.get('DB_NAME'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASS')
    )
    register_vector(conn)
    return conn

@app.route('/healthz')
def healthz():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
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

        if 'q' in request.args:
            query = request.args['q']
            embedding = genai.embed_content(model=model, content=query)["embedding"]
            cur.execute("SELECT * FROM games ORDER BY embedding <=> %s LIMIT 5;", (embedding,))
        else:
            cur.execute('SELECT * FROM games;')

        games = cur.fetchall()
        cur.close()
        conn.close()

        # Convert the results to a list of dictionaries
        columns = [desc[0] for desc in cur.description]
        games_list = [dict(zip(columns, row)) for row in games]
        return jsonify(games_list)

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
