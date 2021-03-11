--
-- Файл сгенерирован с помощью SQLiteStudio v3.3.2 в Wed Mar 10 22:40:37 2021
--
-- Использованная кодировка текста: UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Таблица: entities
CREATE TABLE entities (
    id   INTEGER PRIMARY KEY AUTOINCREMENT
                 NOT NULL
                 UNIQUE,
    name VARCHAR,
    blob BLOB
);


-- Таблица: rooms
CREATE TABLE rooms (
    id       INTEGER PRIMARY KEY AUTOINCREMENT
                     NOT NULL
                     UNIQUE,
    name     VARCHAR,
    entities         REFERENCES entities (name) 
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
