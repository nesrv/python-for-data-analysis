# 3.6. Классы операторов и индексы

**Цель:** по плану запроса выбрать метод доступа и класс операторов, затем проверить на данных, что индекс ускорил нужное условие и не мешает там, где он бесполезен.

**Опора:** контейнер PostgreSQL из раздела 3.1, база `course`, пользователь `student`. Запросы сохраняйте в `module-3/module-3-6/sql/indexes.sql`.

Индекс — отдельная структура рядом с таблицей. Метод доступа задаёт её устройство: `btree`, `gist`, `gin`, `brin`, `hash`. Класс операторов говорит, какие операции этот индекс умеет ускорять для конкретного типа. Семейство операторов собирает совместимые классы, чтобы в одном индексе можно было сравнивать родственные типы, например `smallint`, `integer` и `bigint`.

| Метод | Что хранит | Какие условия обычно ускоряет |
|-------|------------|-------------------------------|
| `btree` | упорядоченные ключи | `=`, `<`, `<=`, `>`, `>=`, `BETWEEN` |
| `gist` | обобщённое дерево | пересечение диапазонов `&&`, соседство точек |
| `gin` | элементы составного значения | вхождение в `jsonb`, массив, полнотекст |
| `brin` | сводка по блокам таблицы | большие таблицы, значения растут вместе с записью на диск |
| `hash` | код ключа | только `=` |

Класс `text_ops` у `btree` сравнивает строки по правилам локали. Префикс `LIKE 'Ан%'` в русскую локаль через этот класс обычно не попадает. Для такого поиска берут класс `text_pattern_ops`: он сравнивает байты слева направо и умеет ограничение по началу строки.

План смотрят так:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
```

`Seq Scan` читает таблицу подряд. `Index Scan` идёт по индексу и достаёт строки. `Bitmap Index Scan` сначала собирает адреса строк из индекса, затем читает таблицу. В узле плана смотрят `actual time`, `rows` и `Buffers`. Один замер на холодном кэше и на горячем различается, поэтому сравнивают два плана одного и того же запроса подряд, а не абсолютные миллисекунды с чужого компьютера.

Индекс не используется, если условие закрывает почти всю таблицу или столбец обёрнут функцией: `lower(visitor)` — это уже не столбец `visitor`.

---

## Подготовка

```sql
DROP TABLE IF EXISTS visits;

CREATE TABLE visits (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    visitor text NOT NULL,
    city text NOT NULL,
    visited_on date NOT NULL,
    during int4range NOT NULL
);

INSERT INTO visits (visitor, city, visited_on, during)
SELECT
    'u' || (g % 400),
    CASE WHEN g % 20 = 0 THEN 'Москва' ELSE 'город' || (g % 40) END,
    DATE '2024-01-01' + (g % 365),
    int4range(g % 80, (g % 80) + 15, '[)')
FROM generate_series(1, 40000) AS g;

ANALYZE visits;
```

Сорок тысяч строк. Посетителей 400, поэтому поиск одного `visitor` выбирает около ста строк. Город «Москва» встречается у каждой двадцатой строки.

---

## 3.6.1. План без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE visitor = 'u7';
```

В плане нет узла `Index Scan` по `visitor`: у столбца только первичный ключ по `id`. Узел `Seq Scan` показывает, что прочитана вся таблица, а фильтр оставил часть строк.

**Критерий 3.6.1:** в плане есть `Seq Scan` по `visits` и фильтр `visitor = 'u7'`.

---

## 3.6.2. B-дерево и его класс операторов

```sql
CREATE INDEX visits_visitor_idx ON visits (visitor);

SELECT a.amname, c.opcname, c.opcdefault
FROM pg_index i
JOIN pg_class idx ON idx.oid = i.indexrelid
JOIN pg_opclass c ON c.oid = i.indclass[0]
JOIN pg_am a ON a.oid = c.opcmethod
WHERE idx.relname = 'visits_visitor_idx';
```

Индекс создан методом `btree`. Класс по умолчанию для `text` — `text_ops`. В нём есть операторы `<`, `<=`, `=`, `>=`, `>`. Поэтому равенство и диапазон строк индекс может обслужить.

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE visitor = 'u7';
```

Повторите тот же запрос. В плане должен появиться `Index Scan` или `Bitmap Index Scan` по `visits_visitor_idx`.

**Критерий 3.6.2:** у индекса метод `btree` и класс `text_ops`. Поиск `visitor = 'u7'` идёт через этот индекс.

---

## 3.6.3. Когда btree не берётся

Доля «Москвы» велика. Планировщик имеет право оставить `Seq Scan`: читать индекс и потом таблицу дороже, чем пройти таблицу один раз.

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE city = 'Москва';
```

Второе условие ломает индекс по-другому. Функция стоит на столбце, а не на константе:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE lower(visitor) = 'u7';
```

Класс `text_ops` умеет `visitor = 'u7'`. Он не умеет `lower(visitor) = 'u7'`, пока нет индекса по выражению `lower(visitor)`.

**Критерий 3.6.3:** запрос с `lower(visitor)` не использует `visits_visitor_idx`. Для «Москвы» в плане допустим `Seq Scan`.

---

## 3.6.4. Класс text_pattern_ops

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE visitor LIKE 'u1%';
```

Префикс `LIKE` не входит в операторы `text_ops` при обычной локали базы. Создайте второй индекс с явным классом:

```sql
CREATE INDEX visits_visitor_pat_idx
    ON visits (visitor text_pattern_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE visitor LIKE 'u1%';
```

Теперь ограничение по началу строки может идти через `visits_visitor_pat_idx`. Равенство `visitor = 'u7'` по-прежнему обслуживает первый индекс: у `text_pattern_ops` тоже есть `=`, но для равенства достаточно уже созданного `text_ops`.

**Критерий 3.6.4:** запрос `LIKE 'u1%'` использует `visits_visitor_pat_idx`.

---

## 3.6.5. GiST и пересечение диапазонов

Оператор `&&` для `int4range` не входит в btree. Его класс — `range_ops` метода `gist`.

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE during && int4range(10, 20, '[)');
```

```sql
CREATE INDEX visits_during_gist
    ON visits USING gist (during);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM visits
WHERE during && int4range(10, 20, '[)');
```

Второй план использует `visits_during_gist`. Условие `during = int4range(0, 15, '[)')` btree тоже мог бы искать, если бы индекс был по btree. Пересечение `&&` без GiST остаётся фильтром по таблице.

**Критерий 3.6.5:** после создания GiST-индекса узел плана ссылается на `visits_during_gist`.

---

## 3.6.6. Практика. Выбор индекса

Двенадцать заданий на один академический час. Таблица `visits` уже заполнена. Каждый следующий запрос опирается на предыдущий. Ответы и планы дописывайте в `sql/indexes.sql`.

**Задание 1.** Запишите одной фразой, чем метод доступа отличается от класса операторов.

**Решение.**

Метод доступа — устройство индекса, например `btree` или `gist`. Класс операторов — набор операций, которые этот индекс умеет ускорять для типа столбца.

**Задание 2.** Покажите план поиска `visited_on = DATE '2024-06-01'` до создания индекса по дате. Назовите узел, который читает таблицу.

**Решение.**

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM visits WHERE visited_on = DATE '2024-06-01';
```

Таблицу читает `Seq Scan`.

**Задание 3.** Создайте btree-индекс `visits_date_idx` по `visited_on`. Повторите запрос из задания 2 и выпишите имя индекса из плана.

**Решение.**

```sql
CREATE INDEX visits_date_idx ON visits (visited_on);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM visits WHERE visited_on = DATE '2024-06-01';
```

В плане есть `visits_date_idx`.

**Задание 4.** Запросите класс операторов этого индекса из `pg_opclass`. Запишите метод и имя класса.

**Решение.**

```sql
SELECT a.amname, c.opcname
FROM pg_index i
JOIN pg_class idx ON idx.oid = i.indexrelid
JOIN pg_opclass c ON c.oid = i.indclass[0]
JOIN pg_am a ON a.oid = c.opcmethod
WHERE idx.relname = 'visits_date_idx';
```

Метод `btree`, класс `date_ops`.

**Задание 5.** Сравните два плана: `visited_on BETWEEN DATE '2024-01-01' AND DATE '2024-01-07'` и `visited_on >= DATE '2024-12-01'`. Оба должны иметь право пользоваться одним btree, потому что `BETWEEN` и `>=` входят в его класс.

**Решение.**

```sql
EXPLAIN SELECT id FROM visits
WHERE visited_on BETWEEN DATE '2024-01-01' AND DATE '2024-01-07';

EXPLAIN SELECT id FROM visits
WHERE visited_on >= DATE '2024-12-01';
```

Оба плана ссылаются на `visits_date_idx`.

**Задание 6.** Постройте план `WHERE city = 'Москва'` при индексе `CREATE INDEX visits_city_idx ON visits (city)`. Если планировщик оставил `Seq Scan`, запишите почему: условие забирает заметную долю таблицы.

**Решение.**

```sql
CREATE INDEX visits_city_idx ON visits (city);

EXPLAIN SELECT id FROM visits WHERE city = 'Москва';
```

«Москва» есть у каждой двадцатой строки. Чтение почти всей таблицы через индекс часто дороже последовательного прохода, поэтому `Seq Scan` здесь допустим.

**Задание 7.** Индекс по `visitor` уже есть. Покажите план `WHERE upper(visitor) = 'U7'`. Объясните, почему `visits_visitor_idx` в нём не участвует.

**Решение.**

```sql
EXPLAIN SELECT id FROM visits WHERE upper(visitor) = 'U7';
```

Индекс построен по `visitor`, а в условии столбец обёрнут в `upper`. Класс `text_ops` такое выражение не обслуживает.

**Задание 8.** Создайте индекс по выражению `upper(visitor)` и добейтесь, чтобы план задания 7 его использовал.

**Решение.**

```sql
CREATE INDEX visits_visitor_upper_idx ON visits (upper(visitor));

EXPLAIN SELECT id FROM visits WHERE upper(visitor) = 'U7';
```

**Задание 9.** Для `visitor LIKE 'u3%'` создайте индекс с классом `text_pattern_ops`, если обычный btree этот шаблон не берёт. В плане должно быть имя нового индекса.

**Решение.**

```sql
CREATE INDEX visits_visitor_pat_idx ON visits (visitor text_pattern_ops);

EXPLAIN SELECT id FROM visits WHERE visitor LIKE 'u3%';
```

**Задание 10.** Покажите план `during && int4range(40, 50, '[)')` до GiST и после `CREATE INDEX visits_during_gist ON visits USING gist (during)`.

**Решение.**

```sql
EXPLAIN SELECT id FROM visits
WHERE during && int4range(40, 50, '[)');

CREATE INDEX visits_during_gist ON visits USING gist (during);

EXPLAIN SELECT id FROM visits
WHERE during && int4range(40, 50, '[)');
```

До индекса условие фильтрует `Seq Scan`. После него план ссылается на `visits_during_gist`.

**Задание 11.** Узнайте метод и класс индекса `visits_during_gist` тем же запросом, что в задании 4. Ожидаются `gist` и `range_ops`.

**Решение.**

```sql
SELECT a.amname, c.opcname
FROM pg_index i
JOIN pg_class idx ON idx.oid = i.indexrelid
JOIN pg_opclass c ON c.oid = i.indclass[0]
JOIN pg_am a ON a.oid = c.opcmethod
WHERE idx.relname = 'visits_during_gist';
```

**Задание 12.** Для трёх условий запишите, какой индекс оставляете и какой снимаете как лишний: точечный поиск посетителя, префикс `LIKE`, пересечение диапазона `during`. Отдельно напишите, какой из созданных индексов не нужен, если запросы к `upper(visitor)` больше не будут.

**Решение.**

Точечный поиск посетителя закрывает `visits_visitor_idx` (`btree`, `text_ops`). Префикс `LIKE` закрывает `visits_visitor_pat_idx` (`text_pattern_ops`). Пересечение `during` закрывает `visits_during_gist`. Если `upper(visitor)` больше не ищут, индекс `visits_visitor_upper_idx` только замедляет вставку и его снимают.

**Критерий 3.6.6:** в файле есть планы до и после индекса по дате, по выражению `upper(visitor)`, по `text_pattern_ops` и по GiST. Для `visits_during_gist` указаны метод `gist` и класс `range_ops`.

---

## 3.6.7. Самопроверка

1. Почему `text_ops` и `text_pattern_ops` — разные классы одного метода `btree`.
2. В каком случае индекс по столбцу есть, а план всё равно показывает `Seq Scan`.
3. Почему пересечение диапазонов не ускоряют тем же btree, что и дату визита.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | Таблица `visits` заполнена и по ней выполнен `ANALYZE` | ☐ |
| 2 | Поиск `visitor = 'u7'` перешёл с `Seq Scan` на индекс | ☐ |
| 3 | Класс `visits_visitor_idx` — `text_ops` | ☐ |
| 4 | `lower` или `upper` по столбцу не пользуется индексом по самому столбцу | ☐ |
| 5 | `LIKE 'u1%'` или `LIKE 'u3%'` идёт через `text_pattern_ops` | ☐ |
| 6 | `during && ...` идёт через GiST | ☐ |
| 7 | В задании 12 названы индекс, который оставляют, и индекс, который снимают | ☐ |
| 8 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| План не изменился после `CREATE INDEX` | Запрос написан иначе, чем индекс: другая функция, другой столбец, шаблон `LIKE` без `text_pattern_ops` |
| Индекс есть, статистика старая | После массовой вставки нужен `ANALYZE visits` |
| `operator class does not exist` | Класс пишут после столбца: `visitor text_pattern_ops` |
| GiST не создаётся | Метод указан так: `USING gist (during)`, не вторым столбцом btree |
| Сравнивают один миллисекундный замер | Смотрят тип узла и `Buffers`, план снимают дважды |

После занятия слушатель для условия называет метод доступа и класс операторов, проверяет выбор по `EXPLAIN` и не оставляет индекс, который запрос не может использовать.
