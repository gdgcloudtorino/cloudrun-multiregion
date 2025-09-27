
import os
from google import genai
from google import genai
from google.genai.types import EmbedContentConfig
# AttributeError: module 'google.generativeai' has no attribute 'get_embedding_model'
# Configure the generative AI model
print(os.environ.get("GEMINI_API_KEY"))
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
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
    print(response.embeddings)  

embed_content(model=model,content="Kepler\u0027s Planetary Puzzle\nOmaggia il genio di Johannes Kepler, celebre astronomo e matematico, con il Kepler\u0027s Planetary Puzzle, un rompicapo tridimensionale in legno che stimola curiosità e abilità logica. L’obiettivo: smontare e rimontare il puzzle, proprio come Keplero scoprì le leggi del moto dei pianeti.\nUn oggetto affascinante, perfetto per appassionati di scienza, storia e enigmi, e ideale anche come idea regalo originale.\nCaratteristiche Tipologia: rompicapo tridimensionale in legno Ispirazione: Johannes Kepler e le leggi planetarie Funzione: smontare e rimontare il puzzle Uso: gioco di logica, esposizione o regalo")