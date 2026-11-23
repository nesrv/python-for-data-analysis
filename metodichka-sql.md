# Методичка: баги поездок и зажигания на SQL

Та же задача, что в `trip_counter.py` и `ignition_counter.py`, на PostgreSQL 18 из корневого `docker-compose.yml`.
База `course`, пользователь `student`, контейнер `pg18-course`.
Сутки считаются по `device_time` в UTC. Баг суток — модуль разницы двух парных событий больше 1.

| Пара | События в колонке `reason` |
|---|---|
| Поездка | `TRIP_BEGIN` и `TRIP_END` |
| Зажигание | `IGNITION_ON` и `IGNITION_OFF` |

Оконная функция считает значение по соседним строкам и при этом оставляет саму строку на месте. `GROUP BY` схлопывает строки в одну на группу. Здесь группировка даёт итог суток, а окна отвечают на вопросы «что было предыдущим событием» и «как копился перекос внутри дня».

## 1. Что лежит в файле

`for_example_1.csv`, разделитель `;`, первая строка — заголовки.

Для задачи нужны три колонки:

| Колонка | Смысл |
|---|---|
| `device_time` | Unix-время события, секунды с 1970-01-01 UTC |
| `record_number` | Номер записи, порядок при одинаковом времени |
| `reason` | Тип события |

Остальные колонки в этих запросах не участвуют. В файле есть учебные строки `record_number` `990001`–`990007` и `990101`–`990106`. Их и должны найти запросы ниже.

`navigation` тоже похожа на Unix-время, но там встречаются пустые значения, `0` и `4294967295`. Границы периода и сутки берутся только из `device_time`.

## 2. Сервер и таблица

Команды Compose выполняются из корня практики, рядом с `docker-compose.yml`. Образ `postgres:18`, порт `5432`, пароль `student`. Том `pgdata` смонтирован в `/var/lib/postgresql`: это каталог кластера, CSV туда класть нельзя. Файл телеметрии копируется в `/tmp` контейнера отдельно.

```powershell
docker compose up -d
docker compose ps
docker cp .\Analysis-Device\for_example_1.csv pg18-course:/tmp/for_example_1.csv
docker compose exec postgres psql -U student -d course
```

`docker compose ps` должен показать состояние `healthy`: это проверка `pg_isready -U student -d course` из Compose. Дальше приглашение `psql` уже внутри контейнера.

Все колонки файла читаются как `text`: в телеметрии много пустых ячеек, а числа вроде `-1` и `4294967295` не везде являются настоящими измерениями. Нужные поля приводятся к типу уже в запросе. Повторный прогон начинается с `DROP`: `\copy` дописывает строки, а не заменяет таблицу.

```sql
DROP FUNCTION IF EXISTS bug_days();
DROP VIEW IF EXISTS events_utc;
DROP TABLE IF EXISTS events;

CREATE TABLE events (
    received_time           text,
    device_time             text,
    navigation              text,
    record_number           text,
    reason                  text,
    nav__latitude           text,
    nav__longitude          text,
    nav__altitude           text,
    nav__speed              text,
    nav__course             text,
    nav__satellite_count    text,
    nav__hdop               text,
    nav__track              text,
    nav__odometer           text,
    nav__validity           text,
    nav__timestamp          text,
    can__speed              text,
    can__engine_max_speed   text,
    can__track_all          text,
    can__remaining_mileage  text,
    can__remaining_hours    text,
    can__fuel_level         text,
    can__gas_level          text,
    can__gas_pressure       text,
    can__fuel_type          text,
    can__fuel_total_liquid  text,
    can__fuel_total_gas     text,
    can__engine_oil_pressure text,
    can__engine_temperature text,
    can__battery_voltage    text,
    can__soot_mass          text,
    can__airbag_deploy      text,
    can__alternator_malfunction text,
    can__brake_fluid_low    text,
    can__coolant_level_low  text,
    can__flag_security_state text,
    can__flag_alarm         text,
    can__engine_time_all    text,
    can__engine_speed       text,
    can__pressure_axle_1    text,
    can__pressure_axle_2    text,
    can__pressure_axle_3    text,
    can__pressure_axle_4    text,
    can__pressure_axle_5    text,
    power__int_voltage      text,
    power__int_charge       text,
    power__int_ir           text,
    power__int_temperature  text,
    power__int_fault        text,
    power__ext_voltage      text,
    power__ext_fault        text,
    status_flags            text
);
```

`\copy` читает файл на той машине, где запущен клиент `psql`. Таблица к этому моменту уже создана запросом выше. В файле первая колонка записана с BOM, поэтому режим `HEADER MATCH` не подходит: сервер видит имя `\ufeffreceived_time`. Обычный `HEADER` просто пропускает первую строку и грузит поля по порядку колонок таблицы.

### Контейнер

Клиент `psql` запущен внутри контейнера, поэтому путь — `/tmp`, куда файл попал через `docker cp`.

```sql
\copy events FROM '/tmp/for_example_1.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', ENCODING 'UTF8')
```

### Локальный PostgreSQL

Сервер установлен на Windows, клиент `psql` тоже на Windows. `docker cp` не нужен: `\copy` берёт CSV прямо с диска. Подключение — к своему экземпляру; пользователь, база и порт те, что заданы при установке. Если локальный сервер слушает `5432`, контейнер из Compose на это время останавливают командой `docker compose stop`, иначе порт занят им.

Из каталога `Analysis-Device`:

```powershell
psql -h localhost -p 5432 -U student -d course
```

Слэши в пути прямые: так строка одинаково читается в `psql` на Windows.

```sql
\copy events FROM 'c:/W27/IT-Cloud-Practice/Analysis-Device/for_example_1.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', ENCODING 'UTF8')
```

Если `psql` запущен уже из каталога `Analysis-Device`, достаточно имени файла: `\copy events FROM 'for_example_1.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', ENCODING 'UTF8')`.

Серверный `COPY events FROM 'c:/...'` для этой загрузки не подходит: файл должен быть доступен учётной записи службы PostgreSQL, а не только пользователю, который сидит в `psql`. `\copy` читает файл самим клиентом и передаёт строки на сервер.

Проверка загрузки:

```sql
SELECT count(*) FROM events;
```

Ожидается 40157 строк: 40144 исходные записи плюс 13 добавленных.

## 3. Unix-время и сутки

`to_timestamp(bigint)` возвращает `timestamptz`. Выражение `AT TIME ZONE 'UTC'` переводит его в `timestamp` без пояса, уже в UTC. Дата от этого значения — календарные сутки задачи.

Порядок сортировки везде один: `device_ts`, затем `record_number`. Иначе строки с одинаковой секундой меняются местами между запусками.

```sql
CREATE VIEW events_utc AS
SELECT
    record_number::bigint AS record_number,
    reason,
    to_timestamp(device_time::bigint) AT TIME ZONE 'UTC' AS device_ts,
    (to_timestamp(device_time::bigint) AT TIME ZONE 'UTC')::date AS day
FROM events
WHERE device_time <> '';
```

Промежуток всех событий — минимум и максимум. Это прямой аналог поиска первой и последней метки в Python.

```sql
SELECT min(device_ts) AS started_at, max(device_ts) AS finished_at
FROM events_utc;
```

Ожидается `2026-10-31 21:26:13` … `2026-11-25 11:00:02`. Верхняя граница сдвинута учебными строками зажигания. Без них конец периода — `2026-11-23 05:21:35`.

## 4. Оконная функция на этом файле

Каркас один и тот же:

```sql
функция() OVER (
    PARTITION BY день      -- внутри каких строк считать
    ORDER BY device_ts, record_number  -- в каком порядке
)
```

`PARTITION BY` делит поток на независимые окна. Без него окно — вся таблица. `ORDER BY` внутри `OVER` задаёт порядок именно для окна. Порядок `SELECT` на него не влияет.

Дальше используются четыре функции:

| Функция | Что возвращает на каждой строке |
|---|---|
| `LAG(x)` | значение `x` у предыдущей строки окна |
| `LEAD(x)` | значение `x` у следующей строки окна |
| `SUM(x) OVER (ORDER BY ...)` | накопленная сумма от начала окна до текущей строки |
| `ROW_NUMBER()` | номер строки внутри окна, с 1 |

## 5. Переход в следующие сутки

`LAG(day)` смотрит на календарную дату предыдущей записи. Строка, у которой дата отличается от предыдущей, и есть переход. У первой строки файла предыдущей даты нет, `LAG` даёт `NULL`, и она тоже попадает в выборку: это начало ряда.

```sql
WITH ordered AS (
    SELECT
        device_ts,
        day,
        LAG(day) OVER (ORDER BY device_ts, record_number) AS prev_day
    FROM events_utc
)
SELECT device_ts AS transition_at, day
FROM ordered
WHERE prev_day IS DISTINCT FROM day
ORDER BY device_ts;
```

`IS DISTINCT FROM` считает `NULL` отдельным значением, поэтому первая строка не теряется в сравнении.

Первые переходы в этом файле:

```text
2026-10-31 21:26:13   2026-10-31
2026-11-01 00:26:13   2026-11-01
2026-11-02 00:00:25   2026-11-02
```

## 6. Баги поездок

Итог суток считается фильтром по `reason`. `::int` превращает логическое значение в 1 или 0, `SUM(...) OVER (PARTITION BY day)` повторяет этот итог на каждой строке дня. `DISTINCT` оставляет одну строку на сутки.

```sql
WITH per_day AS (
    SELECT DISTINCT
        day,
        SUM((reason = 'TRIP_BEGIN')::int) OVER (PARTITION BY day) AS trip_begin,
        SUM((reason = 'TRIP_END')::int)   OVER (PARTITION BY day) AS trip_end
    FROM events_utc
    WHERE reason IN ('TRIP_BEGIN', 'TRIP_END')
)
SELECT
    day,
    trip_begin,
    trip_end,
    abs(trip_begin - trip_end) AS diff
FROM per_day
WHERE abs(trip_begin - trip_end) > 1
ORDER BY day;
```

Ожидаемый результат:

| day | trip_begin | trip_end | diff |
|---|---:|---:|---:|
| 2026-11-01 | 10 | 8 | 2 |
| 2026-11-05 | 10 | 13 | 3 |
| 2026-11-12 | 9 | 7 | 2 |

Тот же итог через `GROUP BY` короче. Окно нужно, когда вместе с итогом надо видеть сами события.

```sql
SELECT
    day,
    count(*) FILTER (WHERE reason = 'TRIP_BEGIN') AS trip_begin,
    count(*) FILTER (WHERE reason = 'TRIP_END')   AS trip_end
FROM events_utc
WHERE reason IN ('TRIP_BEGIN', 'TRIP_END')
GROUP BY day
HAVING abs(
    count(*) FILTER (WHERE reason = 'TRIP_BEGIN')
    - count(*) FILTER (WHERE reason = 'TRIP_END')
) > 1
ORDER BY day;
```

### Как перекос копился внутри дня

Накопленная сумма показывает баланс после каждого события: `TRIP_BEGIN` даёт `+1`, `TRIP_END` даёт `-1`. К концу суток баланс равен `trip_begin - trip_end`.

```sql
SELECT
    day,
    device_ts,
    record_number,
    reason,
    SUM(CASE reason
            WHEN 'TRIP_BEGIN' THEN 1
            WHEN 'TRIP_END' THEN -1
        END) OVER (
            PARTITION BY day
            ORDER BY device_ts, record_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS balance
FROM events_utc
WHERE reason IN ('TRIP_BEGIN', 'TRIP_END')
  AND day IN (DATE '2026-11-01', DATE '2026-11-05', DATE '2026-11-12')
ORDER BY device_ts, record_number;
```

`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` явно задаёт рамку: от первой строки суток до текущей. Для `SUM` с `ORDER BY` такая рамка и есть поведение по умолчанию. Её пишут, чтобы рамка не смешалась с `RANGE`.

### Соседнее событие того же типа

`LAG` в окне только из поездок находит два начала или два конца подряд. Это уже последовательность, а не суточный итог: сутки могут сойтись по счётчику и при этом содержать такой стык.

```sql
WITH seq AS (
    SELECT
        day,
        device_ts,
        record_number,
        reason,
        LAG(reason) OVER (PARTITION BY day ORDER BY device_ts, record_number) AS prev_reason
    FROM events_utc
    WHERE reason IN ('TRIP_BEGIN', 'TRIP_END')
)
SELECT *
FROM seq
WHERE reason = prev_reason
ORDER BY device_ts, record_number;
```

## 7. Баги зажигания

Тот же приём, другие значения `reason`. Комментарий в `ignition_counter.py` называет это двойным срабатыванием: за сутки включений и выключений не поровну, и перекос больше одного.

```sql
WITH per_day AS (
    SELECT DISTINCT
        day,
        SUM((reason = 'IGNITION_ON')::int)  OVER (PARTITION BY day) AS ignition_on,
        SUM((reason = 'IGNITION_OFF')::int) OVER (PARTITION BY day) AS ignition_off
    FROM events_utc
    WHERE reason IN ('IGNITION_ON', 'IGNITION_OFF')
)
SELECT
    day,
    ignition_on,
    ignition_off,
    abs(ignition_on - ignition_off) AS diff
FROM per_day
WHERE abs(ignition_on - ignition_off) > 1
ORDER BY day;
```

Ожидаемый результат:

| day | ignition_on | ignition_off | diff |
|---|---:|---:|---:|
| 2026-11-24 | 3 | 0 | 3 |
| 2026-11-25 | 0 | 3 | 3 |

Двойное срабатывание подряд видно через `LAG` без подсчёта итога. На 24 ноября каждое следующее `IGNITION_ON` совпадает с предыдущим `reason`.

```sql
WITH seq AS (
    SELECT
        day,
        device_ts,
        record_number,
        reason,
        LAG(reason) OVER (PARTITION BY day ORDER BY device_ts, record_number) AS prev_reason
    FROM events_utc
    WHERE reason IN ('IGNITION_ON', 'IGNITION_OFF')
)
SELECT *
FROM seq
WHERE reason = prev_reason
ORDER BY device_ts, record_number;
```

## 8. Одна функция на PL/pgSQL

Функция собирает оба списка. `UNION ALL` складывает результаты двух запросов, колонка `kind` различает пару событий. `RETURN QUERY` отдаёт строки наружу. `LANGUAGE plpgsql` нужен, потому что тело — блок с несколькими операторами; один голый `SELECT` обошёлся бы языком `sql`.

```sql
CREATE OR REPLACE FUNCTION bug_days()
RETURNS TABLE (
    kind    text,
    day     date,
    opened  int,
    closed  int,
    diff    int
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH per_day AS (
        SELECT DISTINCT
            events_utc.day,
            SUM((reason = 'TRIP_BEGIN')::int) OVER (PARTITION BY events_utc.day) AS opened,
            SUM((reason = 'TRIP_END')::int)   OVER (PARTITION BY events_utc.day) AS closed
        FROM events_utc
        WHERE reason IN ('TRIP_BEGIN', 'TRIP_END')
    )
    SELECT
        'trip'::text,
        per_day.day,
        per_day.opened::int,
        per_day.closed::int,
        abs(per_day.opened - per_day.closed)::int
    FROM per_day
    WHERE abs(per_day.opened - per_day.closed) > 1

    UNION ALL

    SELECT
        'ignition'::text,
        per_day.day,
        per_day.opened::int,
        per_day.closed::int,
        abs(per_day.opened - per_day.closed)::int
    FROM (
        SELECT DISTINCT
            events_utc.day,
            SUM((reason = 'IGNITION_ON')::int)  OVER (PARTITION BY events_utc.day) AS opened,
            SUM((reason = 'IGNITION_OFF')::int) OVER (PARTITION BY events_utc.day) AS closed
        FROM events_utc
        WHERE reason IN ('IGNITION_ON', 'IGNITION_OFF')
    ) AS per_day
    WHERE abs(per_day.opened - per_day.closed) > 1

    ORDER BY 1, 2;
END;
$$;
```

Вызов:

```sql
SELECT * FROM bug_days();
```

Ожидается пять строк: три `trip` и две `ignition`, с датами и разницами из таблиц выше.

Имена выходных колонок (`day`, `diff`) внутри функции становятся переменными. Поэтому в запросах поля представления записаны как `events_utc.day` и `per_day.day`: иначе PostgreSQL примет `day` за переменную результата, а не за колонку. `SUM(...) OVER` имеет тип `bigint`, а колонки `opened`, `closed` и `diff` объявлены как `int`, поэтому перед возвратом стоит `::int`.

## 9. Сверка с Python

| Python | SQL |
|---|---|
| `datetime.fromtimestamp(..., timezone.utc).date()` | `(to_timestamp(...) AT TIME ZONE 'UTC')::date` |
| первое `device_time` суток | `LAG(day)` и строка, где день сменился |
| словарь `days[day]["TRIP_BEGIN"]` | `SUM((reason = 'TRIP_BEGIN')::int) OVER (PARTITION BY day)` |
| `abs(...) > 1` | то же условие в `WHERE` или `HAVING` |
| `get_trips` и `get_ignitions` | `bug_days()` |

Обе реализации режут сутки по UTC. Локальный пояс UTC+3 сдвинет границу на три часа, и те же события попадут в другие даты.

## 10. Как это стыкуется с Compose

Параметры берутся из корневого `docker-compose.yml`. Второй контейнер не поднимается: порт `5432` уже занят сервисом `postgres`.

| Compose | Значение в этой задаче |
|---|---|
| `image` | `postgres:18` |
| `container_name` | `pg18-course` |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `student` / `student` |
| `POSTGRES_DB` | `course` |
| `ports` | `localhost:5432` с компьютера, `5432` внутри контейнера |
| `pgdata:/var/lib/postgresql` | данные кластера; папку проекта сюда не монтируют |
| `healthcheck` | `pg_isready -U student -d course` |

Подключение с хоста из DBeaver к контейнеру: хост `localhost`, порт `5432`, база `course`, пользователь и пароль `student`. Локальный сервер загружает тот же CSV командой из раздела 2, с путём `c:/W27/IT-Cloud-Practice/Analysis-Device/for_example_1.csv`.

Остановить контейнер, не стирая загруженные строки: `docker compose stop`. Команда `docker compose down -v` удаляет том `pgdata` вместе с таблицей `events`. Файл `/tmp/for_example_1.csv` при пересоздании контейнера пропадает, CSV тогда копируют через `docker cp` ещё раз.
