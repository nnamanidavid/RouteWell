CREATE TABLE visits (
    id SERIAL PRIMARY KEY,
    count INTEGER NOT NULL DEFAULT 0
);

INSERT INTO visits (id, count) VALUES (1, 0);
