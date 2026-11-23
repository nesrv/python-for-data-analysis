# 10.3. Работа с аналитическими функциями в PostgreSQL

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

Практика, на которой держится занятие, устроена из пяти приёмов. Сначала их смотрят на нескольких строках, потом те же слова применяют к квартирам.

| Приём | Что делает со строками | Где в занятии |
|-------|------------------------|---------------|
| `row_number`, `rank`, `dense_rank`, `lag`, `lead`, `first_value`, `last_value` | не схлопывают таблицу, а дописывают соседнее значение или место | 3.6.1 и 3.6.2 |
| `sum`, `avg`, `min`, `max` с `OVER` | считают итог по окну и оставляют каждую строку на месте | 3.6.2 и 3.6.6 |
| `GROUP BY`, `ROLLUP`, `GROUPING SETS`, `CUBE` | схлопывают строки в итоги разной подробности | 3.6.3 и 3.6.7 |
| `FILTER` и `crosstab` | разворачивают значения в столбцы | 3.6.8 |
| `WITH RECURSIVE` | сам дописывает следующую строку ряда | 3.6.10 |

Окно задают в `OVER`. `PARTITION BY` режет таблицу на независимые группы, как продавец или район. `ORDER BY` внутри окна задаёт порядок, без которого «предыдущая строка» не определена. Рамка `ROWS BETWEEN ... AND CURRENT ROW` говорит, что сумма идёт с начала группы до текущей строки, а не по всей группе сразу.

Первая таблица практики — девять сделок. В занятии продавцы названы по-русски, суммы те же.

| Продавец | Дата | Сумма |
|----------|------|-------|
| Анна | 2024-01-01 | 100 |
| Анна | 2024-01-05 | 200 |
| Анна | 2024-01-10 | 300 |
| Борис | 2024-01-02 | 400 |
| Борис | 2024-01-07 | 100 |
| Борис | 2024-01-08 | 600 |
| Вера | 2024-01-03 | 300 |
| Вера | 2024-01-10 | 300 |
| Вера | 2024-01-12 | 300 |

На этих строках проверяют четыре вопроса практики:

1. На сколько текущая сделка отличается от предыдущей у того же продавца. У Анны оба шага по 100. У Бориса скачок 100 → 600 даёт 500.
2. Какая сумма будет следующей. У последней сделки продавца следующей нет, там пусто.
3. Дата первой и последней сделки. У `last_value` без рамки до конца окна «последняя» совпадает с текущей строкой.
4. Место по сумме. У Веры три сделки по 300: `rank` ставит всем место 1, `row_number` всё равно выдаёт 1, 2 и 3.

Накопительная сумма Анны по дате: 100, затем 300, затем 600. Это `sum(amount) OVER (PARTITION BY seller ORDER BY sale_date)`, а не `GROUP BY`: строки сделок остаются в ответе.

Вторая короткая таблица практики — товар и месяц. Её разворачивают в столбцы: одна строка на товар, столбец на месяц.

| Товар | Месяц | Сумма |
|-------|-------|-------|
| Товар А | янв | 100 |
| Товар А | фев | 120 |
| Товар Б | янв | 80 |
| Товар Б | фев | 90 |

После поворота у товара А в столбце «янв» стоит 100, в столбце «фев» — 120. У товара Б соответственно 80 и 90. В отчёте по квартирам так же поступают с районами: не список строк, а столбец на район.

Третья таблица — продавец и товар, чтобы одним запросом получить и клетку «продавец + товар», и итог продавца, и общий итог.

| Продавец | Товар | Сумма |
|----------|-------|-------|
| Анна | виджет | 100 |
| Анна | гаджет | 150 |
| Борис | виджет | 200 |
| Борис | гаджет | 50 |
| Вера | виджет | 300 |
| Вера | гаджет | 75 |

Итог Анны 250, Бориса 250, Веры 375. Общая сумма 875. `ROLLUP` строит эту лесенку сам. `CUBE` добавляет ещё итог по товару без продавца. `GROUPING SETS` перечисляет только те уровни, которые нужны в отчёте. На квартирах те же три уровня: район и комнаты, район целиком, вся таблица.

**Итоговые артефакты** (в папке `module-3/module-3-6/`):

| Файл | Назначение |
|------|------------|
| `sql/flats_report.sql` | Схема `analytics` и пустая таблица `flats` |
| `lab36-report.sql` | Четыре запроса отчёта, их пишет слушатель |

---

Дальше запросы идут от короткой таблицы к отчёту на 10000 строк. Сначала девять сделок: на них видно, чем отличаются нумерации. Потом загрузка квартир и сводки.

## 3.6.1. Номер строки, место и одинаковые цены

`row_number`, `rank` и `dense_rank` нумеруют строки внутри окна. Расходятся они там, где значения равны. На девяти сделках это видно сразу, без файла квартир.

Схему создают один раз. Перед повторным запуском таблицу удаляют, иначе девять строк вставятся ещё раз.

```sql
CREATE SCHEMA IF NOT EXISTS analytics;

DROP TABLE IF EXISTS analytics.sales;

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

У Веры три одинаковые суммы. `row_number` всё равно выдаст 1, 2 и 3: место уникально. `rank` поставит всем троим 1, а следующая другая сумма получила бы 4: номера 2 и 3 пропущены. `dense_rank` тоже поставит 1, но следующий другой уровень был бы 2, без дырки.

**Критерий 3.6.1.** Девять строк. У Веры в колонке `rnk` три единицы. У Анны суммы 300, 200 и 100 получают места 1, 2 и 3 во всех трёх нумерациях: равных сумм у неё нет.

---

## 3.6.2. Соседняя сделка и накопленная сумма

`lag` смотрит на предыдущую строку окна, `lead` — на следующую. У первой строки предыдущей нет, там `NULL`. Таблица та же, `analytics.sales`.

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

`lead` смотрит вперёд по тому же порядку. У последней сделки продавца следующей суммы нет.

```sql
SELECT seller, sale_date, amount,
       lead(amount) OVER (PARTITION BY seller ORDER BY sale_date) AS next_amount
FROM analytics.sales
ORDER BY seller, sale_date;
```

У Анны следующие суммы **200**, **300** и пусто.

Те же рамки окна принимают не только `sum`. `avg` — средний чек с начала до текущей строки, `min` и `max` — меньшая и большая сумма на этом отрезке, `count` — сколько сделок уже прошло.

```sql
SELECT seller, sale_date, amount,
       round(avg(amount) OVER (
           PARTITION BY seller ORDER BY sale_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ), 2) AS running_avg,
       min(amount) OVER (
           PARTITION BY seller ORDER BY sale_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS min_so_far,
       max(amount) OVER (
           PARTITION BY seller ORDER BY sale_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS max_so_far,
       count(*) OVER (
           PARTITION BY seller ORDER BY sale_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS deals_so_far
FROM analytics.sales
ORDER BY seller, sale_date;
```

У Анны средний чек по шагам **100**, **150**, **200**. Минимум всё время **100**. Максимум **100**, затем **200**, затем **300**. Сделок к каждой строке **1**, **2**, **3**.

Сделка выше своего накопительного среднего — это сравнение строки с окном, не отдельная функция:

```sql
SELECT seller, sale_date, amount
FROM (
    SELECT seller, sale_date, amount,
           avg(amount) OVER (
               PARTITION BY seller ORDER BY sale_date
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS running_avg
    FROM analytics.sales
) steps
WHERE amount > running_avg
ORDER BY seller, sale_date;
```

У Анны условие выполняют вторая сделка (200 > 150) и третья (300 > 200). Первая равна своему среднему и в список не входит.

Обычные агрегаты без `OVER` схлопывают продавца в одну строку. `string_agg` склеивает суммы в текст:

```sql
SELECT seller,
       count(*) AS deals,
       min(amount) AS min_amount,
       max(amount) AS max_amount,
       string_agg(amount::text, ', ' ORDER BY sale_date) AS amounts
FROM analytics.sales
GROUP BY seller
ORDER BY seller;
```

У Анны три сделки, минимум 100, максимум 300, строка сумм `100, 200, 300`. У Веры минимум и максимум совпадают: все три суммы равны 300.

**Критерий 3.6.2.** Первые даты: Анна 2024-01-01, Борис 2024-01-02, Вера 2024-01-03. Последние: Анна 2024-01-10, Борис 2024-01-08, Вера 2024-01-12. Следующая сумма первой сделки Анны — **200**. Её накопительное среднее на третьей строке — **200**. В списке сделок выше своего среднего у Анны две строки.

---

## Подготовка квартир

Контейнер запущен. Схема уже есть после раздела 3.6.1. Пустая таблица и загрузка файла:

```powershell
docker exec pg18-course psql -U student -d course -c "CREATE SCHEMA IF NOT EXISTS analytics;"
Get-Content -Raw -Encoding utf8 module-3\module-3-6\sql\flats_report.sql | docker exec -i pg18-course psql -U student -d course
docker cp module-6-0\data\flats.csv pg18-course:/tmp/flats.csv
docker exec pg18-course psql -U student -d course -c "\copy analytics.flats FROM '/tmp/flats.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
```

`docker cp` кладёт файл внутрь контейнера. `\copy` в этой команде читает уже путь контейнера, не путь Windows.

Если PostgreSQL 18 стоит в Windows и контейнера нет, файл читает клиентский `\copy` прямо с диска. Команды запускают из корня курса. Каталог `bin` установленного сервера должен быть в `PATH`, либо вместо `psql` пишут полный путь, например `"C:\Program Files\PostgreSQL\18\bin\psql.exe"`. Пользователь и база те же: `student` и `course`. Пароль спросит `psql`.

```powershell
psql -U student -d course -c "CREATE SCHEMA IF NOT EXISTS analytics;"
Get-Content -Raw -Encoding utf8 module-3\module-3-6\sql\flats_report.sql | psql -U student -d course
psql -U student -d course -c "\copy analytics.flats FROM 'module-6-0/data/flats.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
```

Здесь `\copy` забирает `module-6-0/data/flats.csv` с компьютера, где открыт терминал. Серверный `COPY` без обратной косой черты для этого не нужен: он ищет файл уже на стороне сервера и требует прав суперпользователя.

Проверка загрузки:

```powershell
docker exec pg18-course psql -U student -d course -c "SELECT count(*), sum(price), round(avg(price), 2) FROM analytics.flats;"
```

Без контейнера та же проверка:

```powershell
psql -U student -d course -c "SELECT count(*), sum(price), round(avg(price), 2) FROM analytics.flats;"
```

**Критерий 3.6.0.** Строк **10000**, сумма цен **67412226**, среднее **6741.22**.

Дальше запросы набирают в DBeaver или дописывают в `module-3/module-3-6/lab36-report.sql`. Файл прогоняют так же, как скрипт создания таблицы: через `docker exec -i` или через `psql -U student -d course`.

---

## 3.6.3. Сводка по району

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

**Критерий 3.6.3.** Пять районов. Дороже всех центр: **1985** квартир, среднее **7330.89**, медиана **7335**. Дальше юг (среднее 6707.83), запад (6703.78), север (6596.82), восток (6372.72). Число квартир: юг 2002, запад 1965, север 2060, восток 1988.

---

## 3.6.4. Цена по десятилетиям

Год сам по себе слишком мелкий для графика. `year / 10 * 10` с целочисленным делением даёт начало десятилетия: 1994 превращается в 1990.

```sql
SELECT (year / 10) * 10 AS decade,
       count(*) AS flats,
       round(avg(price), 2) AS avg_price
FROM analytics.flats
GROUP BY decade
ORDER BY decade;
```

**Критерий 3.6.4.** Семь строк, с 1960 по 2020. Квартир: 1284, 1582, 1583, 1626, 1582, 1557, 786. В 2020-х строк меньше, потому что в файле годы только до 2024, десятилетие не полное.

---

## 3.6.5. Самые дорогие в своём районе

То же окно, что в разделе 3.6.1, теперь на квартирах. Оно не схлопывает таблицу в одну строку на район, а дописывает каждой квартире место. В отчёт оставляют первое место. На этих данных максимум в районе один, поэтому `row_number` и `rank` совпали бы.

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

**Критерий 3.6.5.** Пять строк, по одной на район. Первая — центр, `flat_id` **1733**, 120 м², 2024 год, 4 комнаты, цена **11625**.

---

## 3.6.6. Цена центра к прошлому году

`lag` с раздела 3.6.2 переносится на сводку. Сначала год сворачивается в одно среднее, потом окно смотрит на предыдущий год. У первого года предыдущего нет, дельта пустая.

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

**Критерий 3.6.6.** 1962 год среднее **6992.79** и пустая дельта, 1963 год **7708.57** и дельта **715.78**, 1964 год **6614.97** и дельта **-1093.60**.

---

## 3.6.7. Несколько итогов одним запросом

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

`CUBE` на квартирах даёт длинный ответ. Тот же разрез сначала смотрят на шести строках «продавец и товар», чтобы увидеть все четыре уровня: клетка, итог продавца, итог товара и общий итог.

```sql
DROP TABLE IF EXISTS analytics.goods;

CREATE TABLE analytics.goods (
    seller text NOT NULL,
    product text NOT NULL,
    amount integer NOT NULL
);

INSERT INTO analytics.goods (seller, product, amount) VALUES
    ('Анна', 'виджет', 100),
    ('Анна', 'гаджет', 150),
    ('Борис', 'виджет', 200),
    ('Борис', 'гаджет', 50),
    ('Вера', 'виджет', 300),
    ('Вера', 'гаджет', 75);

SELECT seller, product, sum(amount) AS total_amount
FROM analytics.goods
GROUP BY CUBE (seller, product)
ORDER BY seller NULLS LAST, product NULLS LAST;
```

Клетка Анны и виджета — **100**. Итог Анны, строка с пустым товаром, — **250**. Итог всех виджетов, строка с пустым продавцом, — **600**. Итог гаджетов — **275**. Общий итог, где пусты оба столбца, — **875**.

`CUBE (district, rooms)` на квартирах добавляет тот же лишний для этого отчёта разрез: итог по числу комнат сразу по всем районам. Для отчёта «сначала район, внутри него комнаты» хватает `ROLLUP`.

**Критерий 3.6.7.** В `CUBE` по товарам общий итог **875**, виджеты **600**, гаджеты **275**, итог Анны **250**. По квартирам строка, где пусты и район, и комнаты, имеет сумму **67412226**. Строка центра без комнат — **14551817**. Клетки центра: 1 комната **1263020**, 2 комнаты **2699724**, 3 комнаты **6032969**, 4 комнаты **4556104**.

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

Тот же поворот на четырёх строках практики делает `crosstab`. Ему нужно расширение `tablefunc` и заранее названные столбцы месяцев. Первый аргумент — запрос из трёх колонок: строка, будущий столбец, значение. Второй — список этих столбцов.

```sql
CREATE EXTENSION IF NOT EXISTS tablefunc;

DROP TABLE IF EXISTS analytics.month_sales;

CREATE TABLE analytics.month_sales (
    product text NOT NULL,
    month text NOT NULL,
    sales_amount integer NOT NULL
);

INSERT INTO analytics.month_sales (product, month, sales_amount) VALUES
    ('Товар А', 'янв', 100),
    ('Товар А', 'фев', 120),
    ('Товар Б', 'янв', 80),
    ('Товар Б', 'фев', 90);

SELECT *
FROM crosstab(
    $$SELECT product, month, sales_amount
      FROM analytics.month_sales
      ORDER BY 1, 2$$,
    $$VALUES ('янв'), ('фев')$$
) AS ct(product text, jan integer, feb integer);
```

У товара А в столбце `jan` число **100**, в `feb` — **120**. У товара Б — **80** и **90**. Для пяти районов в большом отчёте короче `FILTER`: не нужно расширение и не нужно перечислять имена столбцов в типе результата.

**Критерий 3.6.8.** Семь десятилетий, два столбца средних. Пустых средних нет: в каждом десятилетии есть и центр, и восток.

---

## 3.6.9. Свёртка, которую не пересчитывают каждый раз

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

**Критерий 3.6.9.** Чтение представления даёт те же пять районов и то же среднее центра **7330.89**, что запрос из 3.6.3. `REFRESH` без новой загрузки эти числа не меняет.

---

## 3.6.10. Рекурсия — не свёртка таблицы

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

**Критерий 3.6.10.** Десять строк. В последней `n` равен **10**, `fact` равен **3628800**.

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
