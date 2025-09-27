CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    game_embedding VECTOR(768)
);
-- https://cloud.google.com/sql/docs/postgres/understand-example-embedding-workflow?hl=it
CREATE INDEX games_embed_idx ON games
  USING hnsw (embedding vector_cosine_ops);

INSERT INTO games (name, description)
VALUES (
  'Congress of Vienna',
    'Congress of Vienna: Un''Esperienza di Strategia Diplomatica
    Congress of Vienna (CoV) è un gioco di strategia diplomatica per uno a quattro giocatori. Basato su Churchill, il premiato design di Mark Herman, CoV è stato accolto positivamente durante il Weekend al Warehouse di GMT nella primavera del 2019 e durante la CSW Expo di giugno a Tempe, Arizona. Questo gioco è il terzo della serie "Great Statesmen" di GMT, dopo Churchill e Pericles. Scenari di Gioco Coinvolgenti
    Congress of Vienna crea un''arena di gioco avvincente. Permette ai giocatori di diventare i protagonisti della drammatica e titanica lotta tra l''Impero Napoleonico in declino e la coalizione di Russia, Austria e Gran Bretagna (con i loro alleati prussiani, spagnoli, portoghesi e svedesi). Il gioco inizia dopo la disastrosa ritirata di Napoleone da Mosca nel 1812, coprendo gli anni decisivi del 1813 e 1814. Mappe Strategiche e Scenari Storici
    La mappa astratta del gioco coinvolge un teatro strategico che rappresenta l''Europa dalla Penisola Iberica fino ai confini della Polonia e della Prussia. Include anche il fronte secondario dell''Italia, un''area per rappresentare la guerra marittima e la guerra anglo-americana del 1812. Questo gioco, creato dal designer Frank Esparrago e dallo sviluppatore Dick Sauer (con il prezioso contributo di Mark Herman), è stato progettato per essere giocato sia come conflitto diplomatico che strategico militare, senza perdere il sapore delle grandi battaglie dell''era napoleonica. Componenti di Gioco Dettagliati
    Tutte le tabelle necessarie per il gameplay sono stampate sul tabellone di gioco. Congress of Vienna riproduce lo spirito di Churchill nelle meccaniche e nell''organizzazione delle sue regole, nei display diplomatici e nella sua mappa militare. Questa attenzione ai dettagli rende il gioco non solo una sfida strategica, ma anche un''esperienza immersiva nel contesto storico del periodo napoleonico. Acquista Congress of Vienna
    Se sei un appassionato di giochi di strategia diplomatica e ti affascina l''era napoleonica, Congress of Vienna è un''aggiunta imperdibile alla tua collezione. Acquista ora e immergiti in uno dei periodi più tumultuosi della storia europea.'
    );
-- the function is available only on cloud sql with ml enabled
--UPDATE games SET game_embedding = embedding('gemini-embedding-001', description) WHERE game_embedding is null;