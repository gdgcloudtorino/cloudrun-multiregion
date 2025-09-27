
import os
from flask import Flask, jsonify, request
import psycopg
from pgvector.psycopg import register_vector
from google import genai
from google.genai.types import EmbedContentConfig
app = Flask(__name__)
# AttributeError: module 'google.generativeai' has no attribute 'get_embedding_model'
# Configure the generative AI model
client = genai.Client(
        api_key=os.environ.get("GEMINI_API_KEY"),
    )
model="gemini-embedding-001"
def embed_content(model,content):
    response = client.models.embed_content(
        model=model,
        contents=[
            content,
        ],
        config=EmbedContentConfig(
            #task_type="RETRIEVAL_DOCUMENT",  # Optional
            #output_dimensionality=3072,  # Optional
            #title="Game description",  # Optional
        ),
    )
    return response.embeddings    
def get_db_connection():
    conn = psycopg.connect(
        host=os.environ.get('DB_HOST'),
        dbname=os.environ.get('DB_NAME'),
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

@app.route('/api/games', methods=['GET'])
def get_games():
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        if 'q' in request.args:
            query = request.args['q']
            embedding = embed_content(model=model, content=query)[0].values
            cur.execute("SELECT * FROM games ORDER BY game_embedding <=> %s::vector LIMIT 5;", (embedding,))
        else:
            cur.execute('SELECT * FROM games;')

        games = cur.fetchall()
        
        # Get column names from the cursor description
        columns = [desc[0] for desc in cur.description]
        games_list = [dict(zip(columns, row)) for row in games]

        cur.close()
        conn.close()

        return jsonify(games_list)

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/games', methods=['POST'])
def create_game():
    try:
        data = request.get_json()
        name = data.get('name')
        description = data.get('description')

        if not name or not description:
            return jsonify({'error': 'Name and description are required.'}), 400

        embedding = embed_content(model=model, content=description)[0].values

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO games (name, description, game_embedding) VALUES (%s, %s, %s::vector) RETURNING *;",
            (name, description,embedding)
        )
        new_game = cur.fetchone()
        conn.commit()

        # Get column names from the cursor description
        columns = [desc[0] for desc in cur.description]
        new_game_dict = dict(zip(columns, new_game))

        cur.close()
        conn.close()

        return jsonify(new_game_dict), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
