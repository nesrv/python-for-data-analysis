-- Отчёт по квартирам в обычном PostgreSQL.
-- Таблицу analytics.flats заранее наполняет команда \copy из методички.
-- Повторный запуск убирает старый отчёт и собирает его заново.

DROP MATERIALIZED VIEW IF EXISTS analytics.price_by_district;
DROP TABLE IF EXISTS analytics.flats;

CREATE TABLE analytics.flats (
    flat_id integer PRIMARY KEY,
    district text NOT NULL,
    area integer NOT NULL,
    year integer NOT NULL,
    rooms integer NOT NULL,
    price integer NOT NULL,
    price_note text NOT NULL
);

-- Файл копируют с хоста в контейнер, см. методичку.
-- \copy analytics.flats FROM '/tmp/flats.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
