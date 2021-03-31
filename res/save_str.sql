--
-- Файл сгенерирован с помощью SQLiteStudio v3.3.2 в Mon Mar 22 21:03:57 2021
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


-- Таблица: rooms
CREATE TABLE rooms (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR,
    tmx  TEXT
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
