# 3.6. PostgreSQL как база для аналитики

**Цель:** собрать отчёт по 10000 квартир запросами в PostgreSQL и понять, какой отчёт остаётся в этой базе, а какой тянет отдельную колоночную СУБД.

**Опора:** контейнер `pg18-course`, база `course`, пользователь `student` из раздела 3.1. Файл `module-6-0/data/flats.csv`. Рабочая папка — корень курса.

Аналитический вопрос здесь один: как устроены цены по районам и годам. Строки почти не правят, их много раз читают целиком и сворачивают. Для такого чтения часто берут ClickHouse. На этом объёме тот же отчёт считается в PostgreSQL, который уже стоит в курсе.

Чем запросы отличаются от обычной операционной таблицы:

| | Операционная работа | Этот отчёт |
|--|--|--|
| Что делают со строкой | находят одну квартиру по номеру и правят её | проходят все 10000 и считают среднее |
| Полезный индекс | по `flat_id` | часто ни один: читают почти всю таблицу |
| Что сохраняют | сами строки | готовую свёртку, чтобы не считать её каждый раз |

`price_note` в отчёт не входит. Это подпись «цена N», она повторяет ответ и для сводки не нужна.

**Итоговые артефакты** (в папке `module-3/module-3-6/`):

| Файл | Назначение |
|------|------------|
| `sql/flats_report.sql` | Схема `analytics` и пустая таблица `flats` |
| `lab36-report.sql` | Четыре запроса отчёта, их пишет слушатель |

---

## Подготовка

Контейнер запущен. Схема и пустая таблица:

```powershell
docker exec pg18-course psql -U student -d course -c "CREATE SCHEMA IF NOT EXISTS analytics;"
Get-Content -Raw -Encoding utf8 module-3\module-3-6\sql\flats_report.sql | docker exec -i pg18-course psql -U student -d course
docker cp module-6-0\data\flats.csv pg18-course:/tmp/flats.csv
docker exec pg18-course psql -U student -d course -c "\copy analytics.flats FROM '/tmp/flats.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
```

`docker cp` кладёт файл внутрь контейнера. `\copy` из psql на сервере читает уже этот путь, не путь Windows.

Проверка загрузки:

```powershell
docker exec pg18-course psql -U student -d course -c "SELECT count(*), sum(price), round(avg(price), 2) FROM analytics.flats;"
```

**Критерий 3.6.0.** Строк **10000**, сумма цен **67412226**, среднее **6741.22**.

Дальше запросы набирают в DBeaver или дописывают в `module-3/module-3-6/lab36-report.sql` и прогоняют тем же `Get-Content | docker exec -i`.

---

## 3.6.1. Сводка по району

Один проход по таблице, пять строк ответа. Так выглядит основной аналитический запрос: не `WHERE flat_id = ...`, а `GROUP BY`.

```sql
SELECT district,
       count(*) AS flats,
       round(avg(price), 2) AS avg_price,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM analytics.flats
GROUP BY district
ORDER BY avg_price DESC;
```

`percentile_cont(0.5)` — медиана. `avg` тянет среднее к редким дорогим квартирам, медиана показывает середину списка.

**Критерий 3.6.1.** Пять районов. Дороже всех центр: **1985** квартир, среднее **7330.89**, медиана **7335**. Дальше юг (среднее 6707.83), запад (6703.78), север (6596.82), восток (6372.72). Число квартир: юг 2002, запад 1965, север 2060, восток 1988.

---

## 3.6.2. Цена по десятилетиям

Год сам по себе слишком мелкий для графика. `year / 10 * 10` с целочисленным делением даёт начало десятилетия: 1994 превращается в 1990.

```sql
SELECT (year / 10) * 10 AS decade,
       count(*) AS flats,
       round(avg(price), 2) AS avg_price
FROM analytics.flats
GROUP BY decade
ORDER BY decade;
```

**Критерий 3.6.2.** Семь строк, с 1960 по 2020. Квартир: 1284, 1582, 1583, 1626, 1582, 1557, 786. В 2020-х строк меньше, потому что в файле годы только до 2024, десятилетие не полное.

---

## 3.6.3. Самые дорогие в своём районе

Оконная функция не схлопывает таблицу в одну строку на район. Она дописывает каждой квартире место в своём районе. В отчёт оставляют первое место.

```sql
SELECT flat_id, district, area, year, rooms, price
FROM (
    SELECT flat_id, district, area, year, rooms, price,
           row_number() OVER (PARTITION BY district ORDER BY price DESC) AS place
    FROM analytics.flats
) ranked
WHERE place = 1
ORDER BY price DESC;
```

`PARTITION BY district` начинает нумерацию заново в каждом районе. `ORDER BY price DESC` ставит единицу самой дорогой.

**Критерий 3.6.3.** Пять строк, по одной на район. Первая — центр, `flat_id` **1733**, 120 м², 2024 год, 4 комнаты, цена **11625**.

---

## 3.6.4. Свёртка, которую не пересчитывают каждый раз

Запросы выше за секунду проходят 10000 строк. Отчёт на экране обновляют чаще, чем данные. Готовую свёртку кладут в материализованное представление: это таблица с результатом, а не запрос, который живёт только пока его выполняют.

```sql
CREATE MATERIALIZED VIEW analytics.price_by_district AS
SELECT district,
       count(*) AS flats,
       round(avg(price), 2) AS avg_price,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM analytics.flats
GROUP BY district;

SELECT district, flats, avg_price
FROM analytics.price_by_district
ORDER BY avg_price DESC;
```

Пока представление не обновили, оно не видит новые вставки в `analytics.flats`. Обновление — отдельная команда, её запускают после загрузки, а не на каждый чих:

```sql
REFRESH MATERIALIZED VIEW analytics.price_by_district;
```

**Критерий 3.6.4.** Чтение представления даёт те же пять районов и то же среднее центра **7330.89**, что запрос из 3.6.1. `REFRESH` без новой загрузки эти числа не меняет.

---

## 3.6.5. Несколько итогов одним запросом

Обычный `GROUP BY district, rooms` даёт только клетки «район и число комнат». В отчёте рядом нужны итог по району и общий итог. `ROLLUP` добавляет их сам: сначала отбрасывает комнаты, потом район.

```sql
SELECT district,
       rooms,
       count(*) AS flats,
       sum(price) AS sum_price
FROM analytics.flats
GROUP BY ROLLUP (district, rooms)
ORDER BY district NULLS LAST, rooms NULLS LAST;
```

Пустой `district` в результате — не ошибка данных. Это строка общего итога. Пустые `rooms` при заполненном районе — итог района по всем планировкам.

`GROUPING SETS` перечисляет те же уровни явно. На этих двух столбцах набор такой:

```sql
SELECT district, rooms, sum(price) AS sum_price
FROM analytics.flats
GROUP BY GROUPING SETS (
    (district, rooms),
    (district),
    ()
)
ORDER BY district NULLS LAST, rooms NULLS LAST;
```

`CUBE (district, rooms)` добавляет ещё один разрез, которого в `ROLLUP` нет: итог по числу комнат сразу по всем районам. Для отчёта «сначала район, внутри него комнаты» хватает `ROLLUP`.

**Критерий 3.6.5.** Строка, где пусты и район, и комнаты, имеет сумму **67412226**. Строка центра без комнат — **14551817**. Клетки центра: 1 комната **1263020**, 2 комнаты **2699724**, 3 комнаты **6032969**, 4 комнаты **4556104**.

---

## 3.6.6. Номер строки, место и одинаковые цены

`row_number`, `rank` и `dense_rank` все нумеруют строки внутри окна. Расходятся они там, где значения равны.

На квартирах максимум в каждом районе один, поэтому `row_number` и `rank` по цене совпали в разделе 3.6.3. Разницу видно на короткой таблице, где суммы повторяются. Это тот же приём, что в задачах на продавцов: три сделки Кэрол по 300.

```sql
CREATE TABLE analytics.sales (
    seller text NOT NULL,
    sale_date date NOT NULL,
    amount integer NOT NULL
);

INSERT INTO analytics.sales (seller, sale_date, amount) VALUES
    ('Анна', DATE '2024-01-01', 100),
    ('Анна', DATE '2024-01-05', 200),
    ('Анна', DATE '2024-01-10', 300),
    ('Борис', DATE '2024-01-02', 400),
    ('Борис', DATE '2024-01-07', 100),
    ('Борис', DATE '2024-01-08', 600),
    ('Вера', DATE '2024-01-03', 300),
    ('Вера', DATE '2024-01-10', 300),
    ('Вера', DATE '2024-01-12', 300);

SELECT seller, sale_date, amount,
       row_number() OVER (PARTITION BY seller ORDER BY amount DESC) AS rn,
       rank()       OVER (PARTITION BY seller ORDER BY amount DESC) AS rnk,
       dense_rank() OVER (PARTITION BY seller ORDER BY amount DESC) AS dense
FROM analytics.sales
ORDER BY seller, amount DESC, sale_date;
```

У Веры три одинаковые суммы. `row_number` всё равно выдаст 1, 2 и 3: место уникально, порядок среди равных не обещан без второго столбца в `ORDER BY`. `rank` поставит всем троим 1, а следующая другая сумма получила бы 4: номера 2 и 3 пропущены. `dense_rank` тоже поставит 1, но следующий другой уровень был бы 2, без дырки.

Повторный запуск вставит те же девять строк ещё раз. Перед повтором таблицу удаляют: `DROP TABLE IF EXISTS analytics.sales;`.

**Критерий 3.6.6.** Девять строк. У Веры в колонке `rnk` три единицы. У Анны суммы 300, 200 и 100 получают места 1, 2 и 3 во всех трёх нумерациях: равных сумм у неё нет.

---

## 3.6.7. Соседняя строка и накопленная сумма

`lag` смотрит на предыдущую строку окна, `lead` — на следующую. У первой строки предыдущей нет, там `NULL`.

Разница с предыдущей сделкой того же продавца:

```sql
SELECT seller, sale_date, amount,
       lag(amount) OVER (PARTITION BY seller ORDER BY sale_date) AS prev_amount,
       amount - lag(amount) OVER (PARTITION BY seller ORDER BY sale_date) AS diff
FROM analytics.sales
ORDER BY seller, sale_date;
```

У Анны вторая сделка 200, предыдущая 100, разница **100**. Третья 300 минус 200 даёт **100**. У Бориса скачок с 100 до 600 даёт **500**.

`first_value` и `last_value` берут край окна. У `last_value` окно по умолчанию кончается на текущей строке, поэтому «последняя» оказывается текущей. Чтобы увидеть конец всего списка продавца, рамку задают явно:

```sql
SELECT DISTINCT seller,
       first_value(sale_date) OVER (PARTITION BY seller ORDER BY sale_date) AS first_date,
       last_value(sale_date) OVER (
           PARTITION BY seller ORDER BY sale_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS last_date
FROM analytics.sales
ORDER BY seller;
```

`DISTINCT` нужен потому, что окно не схлопывает строки: без него каждая сделка повторила бы одни и те же две даты.

Накопительная сумма идёт по дате и не выкидывает строки, в отличие от `GROUP BY`:

```sql
SELECT seller, sale_date, amount,
       sum(amount) OVER (
           PARTITION BY seller ORDER BY sale_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_sum
FROM analytics.sales
ORDER BY seller, sale_date;
```

У Анны накопительные суммы **100**, **300**, **600**.

Тот же приём на квартирах — средняя цена центра по годам и её изменение к прошлому году:

```sql
WITH by_year AS (
    SELECT year,
           round(avg(price), 2) AS avg_price
    FROM analytics.flats
    WHERE district = 'центр'
    GROUP BY year
)
SELECT year,
       avg_price,
       lag(avg_price) OVER (ORDER BY year) AS prev_year,
       round(avg_price - lag(avg_price) OVER (ORDER BY year), 2) AS delta
FROM by_year
ORDER BY year
LIMIT 3;
```

**Критерий 3.6.7.** Первые даты: Анна 2024-01-01, Борис 2024-01-02, Вера 2024-01-03. Последние: Анна 2024-01-10, Борис 2024-01-08, Вера 2024-01-12. Центр по годам: 1962 год среднее **6992.79** и пустая дельта, 1963 год **7708.57** и дельта **715.78**, 1964 год **6614.97** и дельта **-1093.60**.

---

## 3.6.8. Район в столбцы

Сводке иногда нужен не длинный список, а один столбец на район. Без дополнительного модуля это делает `FILTER`: сумма считается только по строкам, которые прошли условие.

```sql
SELECT (year / 10) * 10 AS decade,
       round(avg(price) FILTER (WHERE district = 'центр'), 2) AS centr,
       round(avg(price) FILTER (WHERE district = 'восток'), 2) AS vostok
FROM analytics.flats
GROUP BY decade
ORDER BY decade;
```

Тот же поворот через `crosstab` из модуля `tablefunc` требует расширение и список будущих столбцов заранее. Для пяти районов в отчёте короче `FILTER`. Расширение ставят так:

```sql
CREATE EXTENSION IF NOT EXISTS tablefunc;
```

**Критерий 3.6.8.** Семь десятилетий, два столбца средних. Пустых средних нет: в каждом десятилетии есть и центр, и восток.

---

## 3.6.9. Рекурсия — не свёртка таблицы

В тех же материалах есть `WITH RECURSIVE`: запрос сам дописывает следующую строку, пока выполняется условие. Так считают ряд, а не группу квартир. Для факториала до 10 это выглядит так:

```sql
WITH RECURSIVE factorial(n, fact) AS (
    SELECT 1, 1::bigint
    UNION ALL
    SELECT n + 1, fact * (n + 1)
    FROM factorial
    WHERE n < 10
)
SELECT n, fact FROM factorial ORDER BY n;
```

Первая ветка `UNION ALL` — старт: 1! = 1. Вторая берёт последнюю полученную строку и умножает на следующее число, пока `n` меньше 10. На квартирах такой цикл не нужен: там уже есть готовые строки, их сворачивает `GROUP BY` или окно.

**Критерий 3.6.9.** Десять строк. В последней `n` равен **10**, `fact` равен **3628800**.

---

## Когда этого мало

PostgreSQL здесь уместен: 10000 строк, отчёт из нескольких свёрток, база уже есть, строки иногда всё же правят. ClickHouse берёт другой режим. Туда уносят журнал, который только дописывают, на десятки миллиардов событий, и по нему постоянно считают одни и те же разрезы. Копировать туда справочник квартир города М ради пяти средних не нужно.

Признаки, что отчёт уже тесен этой базе, а не что «аналитика обязана жить в другой СУБД»:

- одна и та же свёртка по сотням миллионов строк считается слишком долго даже из материализованного представления;
- данные только дописываются, старые строки никто не обновляет;
- рядом нет задач, которым нужен тот же PostgreSQL.

Пока этого нет, отчёт остаётся в `analytics`.

| Симптом | Что проверить |
|---------|----------------|
| `relation "analytics.flats" does not exist` | Сначала `flats_report.sql`, схема `analytics` создана |
| `count(*)` не 10000 | `\copy` шёл с `HEADER true` и в файл попал тот же `flats.csv` |
| Медиана центра не 7335 | Считают `percentile_cont(0.5)`, а не `avg` |
| Представление пустое | `CREATE MATERIALIZED VIEW` выполнили после загрузки, не до неё |
| `could not connect` | Контейнер `pg18-course` запущен |
| У Веры в `rnk` номера 1, 2, 3 | Смотрят `rank`, а не `row_number`. Одинаковые суммы должны делить место |
| `last_date` совпадает с датой строки | У `last_value` нет рамки до конца окна |
| Девять строк превратились в восемнадцать | Повторный `INSERT` без `DROP TABLE` |
