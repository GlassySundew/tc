--
-- Файл сгенерирован с помощью SQLiteStudio v3.3.3 в Mon Nov 15 22:45:58 2021
--
-- Использованная кодировка текста: UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Таблица: entities
CREATE TABLE entities (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    name     VARCHAR,
    blob     BLOB,
    level_id INTEGER,
    FOREIGN KEY (
        level_id
    )
    REFERENCES rooms (id) ON DELETE CASCADE
                          ON UPDATE CASCADE
);


-- Таблица: game
CREATE TABLE game (
    blob BLOB
);


-- Таблица: rooms
CREATE TABLE rooms (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR UNIQUE,
    tmx  TEXT
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
