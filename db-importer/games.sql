CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    embedding VECTOR(768)
);

INSERT INTO games (name, description, embedding) VALUES
    ('The Legend of Zelda: Breath of the Wild', 'An action-adventure game set in a large open world.', ARRAY[0.1, 0.2, 0.3, 0.4]),
    ('Red Dead Redemption 2', 'A Western-themed action-adventure game.', ARRAY[0.5, 0.6, 0.7, 0.8]),
    ('The Witcher 3: Wild Hunt', 'An action role-playing game set in a fantasy universe.', ARRAY[0.9, 0.1, 0.2, 0.3]);
