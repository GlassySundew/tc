--
-- Файл сгенерирован с помощью SQLiteStudio v3.3.3 в Fri Dec 10 17:58:17 2021
--
-- Использованная кодировка текста: UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Таблица: entities
CREATE TABLE entities (
    id       INTEGER PRIMARY KEY AUTOINCREMENT
                     UNIQUE,
    name     VARCHAR,
    blob     BLOB,
    level_id INTEGER,
    FOREIGN KEY (
        level_id
    )
    REFERENCES rooms (id) ON DELETE CASCADE
                          ON UPDATE CASCADE,
    FOREIGN KEY (
        id
    )
    REFERENCES players (entity_id) ON DELETE CASCADE
                                   ON UPDATE CASCADE
);


-- Таблица: game
CREATE TABLE game (
    blob BLOB
);


-- Таблица: players
CREATE TABLE players (
    entity_id INT     PRIMARY KEY
                      UNIQUE
                      REFERENCES entities (id) ON DELETE CASCADE
                                               ON UPDATE CASCADE,
    nickname  STRING  UNIQUE,
    feetX     INTEGER,
    feetY     INTEGER
);


-- Таблица: rooms
CREATE TABLE rooms (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR UNIQUE,
    tmx  TEXT
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
