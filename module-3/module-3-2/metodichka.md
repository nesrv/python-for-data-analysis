# 3.2. Хранимые объекты

**Цель:** отличить функцию, процедуру, правило и триггер в PostgreSQL и создать каждый из этих объектов в учебной базе `course`.

**Опора:** контейнер PostgreSQL из раздела 3.1, база `course`, пользователь `student`. Запросы выполняйте в DBeaver или ячейкой SQLAlchemy в `module-3-2/lab32-routines.ipynb`.

**Итоговые артефакты** (в папке `module-3-2/`):

| Файл | Назначение |
|------|------------|
| `lab32-routines.ipynb` | Вызовы функции, процедуры, выборки из набора строк |
| `sql/routines.sql` | Текст всех созданных объектов |

Хранимый объект живёт в базе, а не в ноутбуке. Пока его не удалили, следующий сеанс видит ту же функцию и тот же триггер.

---

## Подготовка

Контейнер `pg18-course` должен быть запущен, таблица `scores` — существовать (её создаёт раздел 3.1). Проверка:

```sql
SELECT name, group_code, score FROM scores ORDER BY name;
```

Если таблицы нет, создайте её и вставьте четыре строки из раздела 3.1: Анна 18, Борис 15, Вера 20, Глеб с пустым баллом.

---

## 3.2.1. Какие объекты бывают

| Объект | Вызов | Что делает |
|--------|--------|------------|
| Функция | внутри выражения, обычно `SELECT` | возвращает значение или набор строк, транзакцию не завершает |
| Процедура | оператор `CALL` | выполняет действия; при вызове отдельной командой может управлять транзакцией |
| Правило `RULE` | само, при `INSERT` / `UPDATE` / `DELETE` | переписывает запрос до выполнения |
| Триггер | сам, до или после строки или оператора | вызывает функцию на событие таблицы |

Функция и процедура делят одно пространство имён: так нельзя назвать и функцию, и процедуру. Текст объекта храните в `sql/routines.sql`, а не правьте только через редактор внутри клиента базы.

**Критерий 3.2.1:** в markdown одной фразой записано, чем `SELECT score_label(18)` отличается от `CALL add_score(...)`.

---

## 3.2.2. Функция на SQL

Функция всегда вызывается как часть выражения. Категория `IMMUTABLE` означает, что при тех же аргументах результат один и тот же и от таблиц не зависит.

```sql
CREATE OR REPLACE FUNCTION score_label(score integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN score IS NULL THEN 'нет балла'
        WHEN score >= 18 THEN 'зачёт с отличием'
        WHEN score >= 12 THEN 'зачёт'
        ELSE 'нужна доработка'
    END;
$$;
```

```sql
SELECT score_label(18), score_label(15), score_label(11), score_label(NULL);
SELECT name, score, score_label(score) FROM scores ORDER BY name;
```

`CREATE OR REPLACE` меняет тело, если функция с таким именем и такими типами аргументов уже есть.

**Практика 3.2.2.** Добавьте функцию `initials(last_name text, first_name text)` категории `IMMUTABLE`. Для `'Иванов'` и `'Иван'` она возвращает `'Иванов И.'`. Проверьте вызовом в `SELECT`.

**Критерий 3.2.2:** `score_label` для 18, 15, 11 и `NULL` даёт четыре разные подписи. `initials` возвращает `'Иванов И.'`.

---

## 3.2.3. Функция, которая читает таблицу

Если результат зависит от данных, но в одном операторе таблица не меняется, ставят `STABLE`, а не `IMMUTABLE`.

```sql
CREATE OR REPLACE FUNCTION score_of(p_name text)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT score FROM scores WHERE name = p_name;
$$;
```

```sql
SELECT score_of('Анна');
```

Пустое имя или отсутствующий человек дают `NULL`, а не ошибку: запрос просто не нашёл строку.

**Критерий 3.2.3:** `score_of('Анна')` равен 18, `score_of('нет такого')` равен `NULL`.

---

## 3.2.4. Процедура

Процедуру вызывают только через `CALL`. Она может не возвращать таблицу, а менять данные. Процедура на языке SQL в этом занятии транзакцию не открывает и не закрывает: для `COMMIT` внутри тела нужен PL/pgSQL и вызов `CALL` вне уже открытой транзакции.

```sql
CREATE OR REPLACE PROCEDURE add_score(
    p_name text,
    p_group text,
    p_score integer
)
LANGUAGE sql
AS $$
    INSERT INTO scores (name, group_code, score)
    VALUES (p_name, p_group, p_score);
$$;
```

```sql
CALL add_score('Олег', 'A', 16);
SELECT name, score, score_label(score) FROM scores WHERE name = 'Олег';
```

**Практика 3.2.4.** Вызовите `add_score` для `'Нины'` из группы `'B'` с баллом 19. Убедитесь, что подпись — «зачёт с отличием».

**Критерий 3.2.4:** в `scores` есть Олег с баллом 16 и Нина с баллом 19.

---

## 3.2.5. Набор строк

`RETURNS TABLE` объявляет функцию, которая возвращает не одно поле, а таблицу. Её ставят в `FROM`, как источник строк. Категория `STABLE`: набор зависит от текущего содержимого `scores`.

```sql
CREATE OR REPLACE FUNCTION passed_scores()
RETURNS TABLE(name text, score integer)
LANGUAGE sql
STABLE
AS $$
    SELECT s.name, s.score
    FROM scores AS s
    WHERE s.score >= 12
    ORDER BY s.name;
$$;
```

```sql
SELECT * FROM passed_scores();
```

Имена столбцов в `RETURNS TABLE` совпадают со столбцами `scores`. В теле запроса таблица названа `s`, иначе `name` внутри функции указывает на выходной столбец, а не на поле таблицы.

**Критерий 3.2.5:** в выборке есть Анна, Борис, Вера, Олег и Нина. Глеба нет: у него балл пустой.

---

## 3.2.6. Курсор

Курсор читает результат запроса по одной строке. В языке SQL курсора нет, его пишут на PL/pgSQL. Для этой задачи набор строк из раздела 3.2.5 короче и уместнее. Курсор нужен, когда следующую строку обрабатывают отдельно от предыдущей.

```sql
CREATE OR REPLACE FUNCTION names_in_order()
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    cur CURSOR FOR SELECT s.name FROM scores AS s ORDER BY s.name;
    rec record;
    acc text := '';
BEGIN
    OPEN cur;
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        acc := acc || rec.name || ' ';
    END LOOP;
    CLOSE cur;
    RETURN acc;
END;
$$;
```

```sql
SELECT names_in_order();
```

`OPEN` выполняет запрос, `FETCH` забирает строку, `NOT FOUND` заканчивает цикл, `CLOSE` освобождает курсор.

**Практика 3.2.6.** В markdown напишите, почему список сдавших в разделе 3.2.5 сделан через `RETURNS TABLE`, а не через курсор.

**Критерий 3.2.6:** строка содержит имена из `scores` в алфавитном порядке, разделённые пробелом. Глеб в ней есть: курсор не фильтрует балл.

---

## 3.2.7. Правило

Правило переписывает запрос до выполнения. `DO ALSO` добавляет ещё одно действие, исходная команда тоже выполняется. `NEW` в правиле на `INSERT` — вставляемая строка.

```sql
CREATE TABLE IF NOT EXISTS scores_log (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text,
    action text,
    at timestamp DEFAULT now()
);

CREATE OR REPLACE RULE scores_log_insert AS
    ON INSERT TO scores
    DO ALSO
    INSERT INTO scores_log (name, action)
    VALUES (NEW.name, 'INSERT');
```

```sql
CALL add_score('Пётр', 'A', 14);
SELECT name, action FROM scores_log WHERE name = 'Пётр';
```

Правило срабатывает на любой `INSERT` в `scores`, в том числе из процедуры `add_score`.

**Критерий 3.2.7:** у Петра есть и строка в `scores`, и строка в `scores_log` с действием `INSERT`.

---

## 3.2.8. Триггер

Триггер вызывает функцию в момент события. Для журнала он обычно уместнее правила: правило переписывает запрос целиком и сложнее читается. Перед триггером снимите правило, иначе журнал получит две записи на одну вставку.

```sql
DROP RULE IF EXISTS scores_log_insert ON scores;

CREATE OR REPLACE FUNCTION scores_log_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO scores_log (name, action)
    VALUES (NEW.name, TG_OP);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS scores_log_trg ON scores;

CREATE TRIGGER scores_log_trg
    AFTER INSERT ON scores
    FOR EACH ROW
    EXECUTE FUNCTION scores_log_fn();
```

`TG_OP` — имя операции, для этого триггера это `INSERT`. `RETURN NEW` обязателен у триггера строки: так строка передаётся дальше.

```sql
CALL add_score('Мария', 'B', 17);
SELECT name, action FROM scores_log WHERE name IN ('Пётр', 'Мария') ORDER BY id;
```

**Практика 3.2.8.** Вставьте ещё одну строку обычным `INSERT`, без процедуры. Убедитесь, что журнал пополнился и без `add_score`.

**Критерий 3.2.8:** у Марии в журнале действие `INSERT`. Новая строка из практики тоже есть в `scores_log`. Правила `scores_log_insert` уже нет.

---

## 3.2.9. Практика. Правила и триггеры

Отдельная практика на один академический час. Двенадцать заданий идут по одной таблице: сначала журнал и мягкое удаление правилами, затем те же действия триггерами. Каждое следующее задание использует объекты предыдущего. Текст дописывайте в `module-3-2/sql/rules-triggers.sql`.

Перед началом снимите учебные объекты этой практики, если запускаете её повторно:

```sql
DROP TABLE IF EXISTS goods_log;
DROP TABLE IF EXISTS goods;
```

**Задание 1.** Создайте таблицу товаров и пустой журнал.

```sql
CREATE TABLE goods (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    price numeric(10, 2) NOT NULL
);

CREATE TABLE goods_log (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    goods_id integer,
    action text NOT NULL,
    at timestamp DEFAULT now()
);
```

**Задание 2.** Правило `goods_log_insert`: при `INSERT` в `goods` исходная вставка остаётся (`DO ALSO`) и в `goods_log` пишется строка с `NEW.id`, действием `'INSERT'`.

**Задание 3.** Вставьте товар `'Бумага'` с ценой `350`. Выберите строку из `goods` и строку из `goods_log`. В журнале одно действие `INSERT`, и `goods_id` совпадает с `id` товара.

**Задание 4.** Добавьте в `goods` столбец `is_deleted boolean NOT NULL DEFAULT false`. Правило `goods_soft_delete`: `ON DELETE TO goods DO INSTEAD` ставит `is_deleted = true` у строки `OLD.id`, а не удаляет её.

**Задание 5.** Выполните `DELETE FROM goods WHERE name = 'Бумага'`. Строка остаётся в `goods`, `is_deleted` равен `true`. Запишите в файл одну фразу: почему `DELETE` не уменьшил число строк.

**Задание 6.** Снимите оба правила.

```sql
DROP RULE IF EXISTS goods_log_insert ON goods;
DROP RULE IF EXISTS goods_soft_delete ON goods;
```

Верните бумаге `is_deleted = false`. Убедитесь, что после `DROP RULE` новый `INSERT` больше не пишет журнал: вставьте `'Карандаш'` за `80` и проверьте, что в `goods_log` по-прежнему одна строка.

**Задание 7.** Функция триггера `goods_log_fn`. Она вставляет в `goods_log` имя операции `TG_OP`. Для `DELETE` берите `OLD.id`, для остальных операций — `NEW.id`.

```sql
CREATE OR REPLACE FUNCTION goods_log_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO goods_log (goods_id, action)
    VALUES (
        CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
        TG_OP
    );
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;
```

**Задание 8.** Триггер `goods_insert_trg`: `AFTER INSERT ON goods FOR EACH ROW`. Вставьте `'Линейка'` за `120`. В журнале появляется вторая строка, действие `INSERT`.

**Задание 9.** Триггер `goods_update_trg`: `AFTER UPDATE ON goods FOR EACH ROW`, та же функция. Поменяйте цену линейки на `150`. В журнале есть действие `UPDATE` с тем же `goods_id`.

**Задание 10.** Функция `goods_price_fn` и триггер `goods_price_trg`: `BEFORE INSERT OR UPDATE`. Если `NEW.price <= 0`, поднимите исключение с текстом `цена должна быть больше нуля`. Иначе верните `NEW`. Проверка: вставка цены `0` не создаёт строку в `goods` и не пишет журнал, потому что строка отклонена до `AFTER INSERT`.

**Задание 11.** Триггер `goods_delete_trg`: `AFTER DELETE`, та же функция журнала. Удалите карандаш обычным `DELETE`. Строки в `goods` больше нет, в журнале есть `DELETE`. Мягкое удаление из задания 4 больше не подменяет команду.

**Задание 12.** В конец `rules-triggers.sql` тремя фразами ответьте: на каком шаге сработало `DO ALSO`, на каком `DO INSTEAD`, почему журнал оставлен на триггерах, а не на правиле.

**Критерий 3.2.9:** в `goods` есть бумага и линейка, карандаша нет. В `goods_log` есть `INSERT`, `UPDATE` и `DELETE`. Нулевая цена отклонена. Оба правила удалены, три триггера на `goods` есть.

---

## 3.2.10. Самопроверка

В `lab32-routines.ipynb` или в конце `sql/routines.sql` ответьте:

1. Почему `score_label` объявлена `IMMUTABLE`, а `score_of` — `STABLE`.
2. Чем `CALL` отличается от вызова функции в `SELECT`.
3. Почему для журнала вставок оставлен триггер, а правило удалено.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | `score_label` и `initials` вызываются из `SELECT` | ☐ |
| 2 | `score_of('Анна')` равен 18 | ☐ |
| 3 | `CALL add_score` добавил Олега и Нину | ☐ |
| 4 | `passed_scores()` возвращает только заполненные баллы от 12 | ☐ |
| 5 | `names_in_order()` собирает имена курсором | ☐ |
| 6 | Журнал `scores_log` пишет вставку триггером | ☐ |
| 7 | Текст объектов лежит в `sql/routines.sql` | ☐ |
| 8 | Практика 3.2.9: журнал `goods_log` содержит `INSERT`, `UPDATE` и `DELETE`, правила сняты | ☐ |
| 9 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| `function score_of(unknown) does not exist` | Аргумент приведите к `text`: `score_of('Анна'::text)` |
| `column reference "name" is ambiguous` | В теле функции таблица названа, поля взяты как `s.name` |
| `CALL` не находится | Это процедура, её нет в списке функций. Смотрите `\df` и процедуры отдельно |
| В журнале две строки на одну вставку | Одновременно живут и правило, и триггер. Правило нужно снять |
| Триггер не создаётся | В PostgreSQL 14 и новее пишут `EXECUTE FUNCTION`, не `EXECUTE PROCEDURE` |
| После пересоздания базы объектов нет | `sql/routines.sql` выполняют заново: объекты не лежат в ноутбуке |

После занятия слушатель кладёт повторяемое вычисление в функцию, изменение данных — в процедуру, а реакцию на вставку — в триггер, и хранит этот текст в файле.
