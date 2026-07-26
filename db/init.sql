

CREATE DATABASE routewell;

\c routewell

CREATE USER routewell WITH PASSWORD 'changeme';
GRANT ALL PRIVILEGES ON DATABASE routewell TO routewell;

CREATE TABLE visits (
    id SERIAL PRIMARY KEY,
    count INTEGER NOT NULL DEFAULT 0
);

INSERT INTO visits (id, count) VALUES (1, 0);

GRANT ALL PRIVILEGES ON TABLE visits TO routewell;
GRANT USAGE, SELECT ON SEQUENCE visits_id_seq TO routewell;
