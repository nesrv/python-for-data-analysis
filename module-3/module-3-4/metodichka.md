# 3.4. Устранение излишней и избыточной информации

**Цель:** из грязной таблицы логов пользователей убрать повторы и поля без новой информации и оставить строки, из которых дальше собирают признаки.

**Опора:** контейнер PostgreSQL из раздела 3.1, база `course`, пользователь `student`. В `.venv` стоят `pandas`, `sqlalchemy` и `psycopg`. Ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка VS Code — корень курса.

**Итоговые артефакты** (в папке `module-3-4/`):

| Файл | Назначение |
|------|------------|
| `sql/user_logs.sql` | Создание и заполнение грязной таблицы |
| `lab34-logs.ipynb` | Чтение из базы, очистка, запись результата |
| таблица `user_logs_ready` | Логи без дублей и лишних столбцов |

Излишняя информация повторяет уже известное: одинаковые события, копия столбца, поле с одним значением на всех строках. Избыточная не входит в вопрос, даже если значения разные: служебный комментарий выгрузки и её номер.

Вопрос занятия: кто, из какого города и канала заходил и сколько секунд длилась сессия.

---

## Подготовка

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install pandas sqlalchemy "psycopg[binary]"
```

Контейнер `pg18-course` запущен. Создайте ноутбук `module-3-4/lab34-logs.ipynb`, ядро — `.venv`. Первая ячейка — markdown: ФИО, дата, заголовок «3.4 Устранение излишней и избыточной информации».

В DBeaver или первой ячейке SQL выполните `module-3-4/sql/user_logs.sql`:

```sql
DROP TABLE IF EXISTS user_logs_ready;
DROP TABLE IF EXISTS user_logs;

CREATE TABLE user_logs (
    export_id integer,
    user_name text,
    user_name_copy text,
    city text,
    channel text,
    seconds integer,
    status text,
    note text
);

INSERT INTO user_logs
    (export_id, user_name, user_name_copy, city, channel, seconds, status, note)
VALUES
    (1, 'Анна',  'Анна',  'Москва', 'поиск',   400, 'imported', 'выгрузка от 12.03'),
    (2, 'Борис', 'Борис', 'Казань', 'реклама', 200, 'imported', 'выгрузка от 12.03'),
    (3, 'Анна',  'Анна',  'Москва', 'поиск',   400, 'imported', 'выгрузка от 12.03'),
    (4, 'Вера',  'Вера',  'Тула',   'письмо',  700, 'imported', 'выгрузка от 12.03'),
    (5, 'Борис', 'Борис', 'Казань', 'реклама', 200, 'imported', 'повтор той же строки'),
    (6, 'Глеб',  'Глеб',  'Москва', 'поиск',   300, 'imported', 'выгрузка от 12.03');
```

Строка 3 повторяет сессию Анны, строка 5 — сессию Бориса. `user_name_copy` совпадает с `user_name`. `status` везде `imported`. `export_id` и `note` различают копии, но к вопросу о сессии не относятся.

---

## 3.4.1. Чтение логов

```python
import pandas as pd
import sqlalchemy as sa

engine = sa.create_engine(
    "postgresql+psycopg://student:student@localhost:5432/course"
)
raw = pd.read_sql(sa.text("SELECT * FROM user_logs ORDER BY export_id"), engine)
print(raw.shape)
print(raw)
```

**Критерий 3.4.1:** в таблице 6 строк и 8 столбцов, кириллица читается.

---

## 3.4.2. Одинаковые строки

Дубль ищут по смыслу сессии, а не по всей строке. `export_id` и `note` у копий разные, поэтому в ключ их не берут.

```python
keys = ["user_name", "city", "channel", "seconds"]
duplicates = raw.duplicated(subset=keys, keep="first")
print(raw.loc[duplicates, ["export_id", "user_name", "note"]])
print("лишних строк:", int(duplicates.sum()))

unique_logs = raw.drop_duplicates(subset=keys, keep="first").copy()
print(unique_logs[["export_id", "user_name", "city", "seconds"]])
print(unique_logs.shape)
```

**Критерий 3.4.2:** лишними помечены выгрузки 3 и 5, после удаления остаётся 4 строки.

---

## 3.4.3. Столбцы-копии

Столбец избыточен, если в каждой строке он равен другому. Имя `user_name_copy` само по себе этого не доказывает.

```python
left = unique_logs.columns.tolist()
copies = []
for i, first in enumerate(left):
    for second in left[i + 1:]:
        if unique_logs[first].equals(unique_logs[second]):
            copies.append((first, second))
print(copies)

without_copies = unique_logs.drop(columns=["user_name_copy"])
print(without_copies.columns.tolist())
```

**Практика 3.4.3.** В markdown запишите, какой столбец из найденной пары оставили и почему.

**Критерий 3.4.3:** в `copies` есть пара `user_name` и `user_name_copy`. После удаления копии столбца `user_name_copy` в таблице нет.

---

## 3.4.4. Столбец без различий

```python
constant = [
    column
    for column in without_copies.columns
    if without_copies[column].nunique(dropna=False) == 1
]
print(constant)
print(without_copies["status"].unique().tolist())

without_constant = without_copies.drop(columns=constant)
print(without_constant.columns.tolist())
```

`nunique(dropna=False)` считает и пропуски. Иначе столбец из одних пустых ячеек можно не заметить.

**Критерий 3.4.4:** в списке постоянных столбцов есть `status`, после удаления его в таблице нет.

---

## 3.4.5. Поля вне вопроса

Для вопроса занятия не нужны номер выгрузки и комментарий оператора. `export_id` различен почти у каждой строки, поэтому проверка на одно значение его не удаляет.

```python
task_columns = ["user_name", "city", "channel", "seconds"]
ready = without_constant[task_columns].copy()
print(ready)
print("строк и столбцов:", ready.shape)
print("сумма секунд", int(ready["seconds"].sum()))
```

**Практика 3.4.5.** Одной фразой объясните, почему `note` удалён, хотя тексты комментариев не все одинаковые.

**Критерий 3.4.5:** в `ready` четыре строки и ровно столбцы `user_name`, `city`, `channel`, `seconds`. Сумма секунд равна **1600** (400 + 200 + 700 + 300).

---

## 3.4.6. Запись обратно в PostgreSQL

```python
ready.to_sql("user_logs_ready", engine, if_exists="replace", index=False)

check = pd.read_sql(sa.text("SELECT * FROM user_logs_ready ORDER BY user_name"), engine)
print(check)
print("сумма секунд", int(check["seconds"].sum()))
```

`if_exists="replace"` пересоздаёт таблицу. Исходная `user_logs` остаётся: по ней видно, что именно удалили.

**Критерий 3.4.6:** в `user_logs_ready` четыре строки, сумма секунд 1600, лишних столбцов нет. Таблица открывается и в DBeaver.

---

## 3.4.7. Самопроверка

В конце ноутбука ответьте:

1. Почему дубли ищут по пользователю, городу, каналу и секундам, а не по всей строке.
2. Чем столбец-копия отличается от столбца с одним значением на всех строках.
3. В каком случае `export_id` нельзя удалять.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | `user_logs` читается из PostgreSQL, 6 строк и 8 столбцов | ☐ |
| 2 | Содержательные дубли — выгрузки 3 и 5, остаётся 4 строки | ☐ |
| 3 | Найдена пара `user_name` / `user_name_copy` | ☐ |
| 4 | Столбец `status` удалён как постоянный | ☐ |
| 5 | В результате только `user_name`, `city`, `channel`, `seconds` | ☐ |
| 6 | `user_logs_ready` в базе, сумма секунд 1600 | ☐ |
| 7 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| `drop_duplicates` ничего не удалил | В `subset` попали `export_id` или `note` |
| Удалили оба столбца из пары | Оставляют `user_name`, удаляют только копию |
| Пропал пользователь | `keep="first"` удаляет повтор, а не все вхождения ключа. Строк должно остаться 4 |
| `note` остался в базе | В `task_columns` его быть не должно |
| `could not connect to server` | Контейнер запущен, в строке подключения база `course` и пользователь `student` |
| В DBeaver пустая `user_logs_ready` | Ячейка записи выполнена, схема — `public` |

После занятия в базе лежит таблица сессий без повторов. Раздел 3.5 приводит её поля к одному виду: город, канал, число секунд и время события.
