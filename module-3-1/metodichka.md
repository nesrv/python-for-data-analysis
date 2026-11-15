# 3.1. Загрузка CSV и JSON

**Цель:** загрузить таблицу из CSV и словарь из JSON, записать оба формата из Python и не перепутать разделитель, кодировку и типы полей.

**Опора:** пути, `with` и UTF-8 из раздела 2.3. Ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка VS Code — корень курса.

**Итоговые артефакты** (в папке `module-3-1/`):

| Файл | Назначение |
|------|------------|
| `lab31-csv.ipynb` | Ноутбук со всеми разделами и сохранённым выводом |
| `data/notes.csv` | Таблица оценок, записанная модулем `csv` |
| `data/summary.txt` | Сводка по загруженной таблице |
| `data/notes-semicolon.csv` | Тот же набор с разделителем `;` |
| `data/incoming.csv` | Файл «как от внешней системы»: `;`, кавычки, пустое поле |
| `data/group.json` | Те же оценки в JSON |
| `data/group-dump.json` | Тот же словарь, записанный через `json.dump` |

---

## Подготовка

Откройте корень курса в VS Code, активируйте окружение и создайте ноутбук `module-3-1/lab31-csv.ipynb`. Выберите ядро `.venv`.

```powershell
.\.venv\Scripts\Activate.ps1
```

Первая ячейка — markdown: ФИО, дата, заголовок «3.1 Загрузка CSV и JSON».

Пути заданы от корня курса (`module-3-1/data/...`). Если `Path.cwd()` — сама папка `module-3-1`, уберите префикс `module-3-1/`.

---

## 3.1.1. Что лежит в CSV

CSV — текст. Строка таблицы — строка файла, поля разделены запятой (или другим символом). Первая строка часто содержит имена столбцов. Перевод строки и запятая внутри поля берутся в кавычки. Модуль `csv` разбирает эти правила. Обычный `split(",")` — нет.

В Windows при записи передают `newline=""`. Иначе между строками появляется лишняя пустая строка: перевод строки добавляет и модуль `csv`, и текстовый режим файла.

**Ячейка — запись:**

```python
import csv
from pathlib import Path

data_dir = Path("module-3-1") / "data"
data_dir.mkdir(parents=True, exist_ok=True)

rows = [
    {"name": "Анна", "score": 18},
    {"name": "Борис", "score": 15},
    {"name": "Вера", "score": 20},
    {"name": "Глеб", "score": 11},
]
table = data_dir / "notes.csv"
with table.open("w", encoding="utf-8", newline="") as file:
    writer = csv.DictWriter(file, fieldnames=["name", "score"])
    writer.writeheader()
    writer.writerows(rows)
print(table.read_text(encoding="utf-8"))
```

Откройте `notes.csv` в VS Code. В статусной строке должна быть кодировка UTF-8.

**Критерий 3.1.1:** в файле пять строк (заголовок и четыре записи), между ними нет пустых строк, имена читаются по-русски.

---

## 3.1.2. Загрузка в словари

`csv.DictReader` сопоставляет поля с заголовком и отдаёт каждую запись словарём. Все значения приходят строками, в том числе числа.

**Ячейка:**

```python
with table.open(encoding="utf-8", newline="") as file:
    loaded = list(csv.DictReader(file))

print(loaded[0])
print(type(loaded[0]["score"]).__name__)

scores = [int(row["score"]) for row in loaded]
lines = [
    f"записей: {len(loaded)}",
    f"сумма баллов: {sum(scores)}",
    f"максимум: {max(scores)}",
]
summary = data_dir / "summary.txt"
summary.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(summary.read_text(encoding="utf-8"))
```

**Практика 3.1.2.** Допишите в сводку строку `сдавших: N`, где N — число баллов `>= 12`.

**Критерий 3.1.2:** тип поля `score` до `int` — `str`. Сумма баллов **64**, максимум **20**, сдавших **3**.

---

## 3.1.3. Загрузка по номерам столбцов

`csv.reader` отдаёт список строк, без имён полей. Так читают файл без заголовка или когда имена ненадёжны. Индекс столбца легко перепутать, поэтому при наличии заголовка предпочтителен `DictReader`.

**Ячейка:**

```python
with table.open(encoding="utf-8", newline="") as file:
    raw_rows = list(csv.reader(file))

header, body = raw_rows[0], raw_rows[1:]
print(header)
print(body[0][0], int(body[0][1]))
print("строк данных:", len(body))
```

**Практика 3.1.3.** По `body` посчитайте сумму второго столбца и сравните её с суммой из `summary.txt`. Результаты должны совпасть.

**Критерий 3.1.3:** заголовок `['name', 'score']`, сумма по индексу `1` равна **64**.

---

## 3.1.4. Другой разделитель и кавычки

Экспорт из таблиц на русской локали часто использует `;`, потому что запятая занята десятичным разделителем. Поле с разделителем внутри берут в кавычки. Кавычка внутри поля удваивается.

**Ячейка — запись с `;`:**

```python
semicolon = data_dir / "notes-semicolon.csv"
with semicolon.open("w", encoding="utf-8", newline="") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=["name", "score", "comment"],
        delimiter=";",
    )
    writer.writeheader()
    writer.writerow({"name": "Анна", "score": 18, "comment": "зачёт; досрочно"})
    writer.writerow({"name": "Борис", "score": 15, "comment": "зачёт"})
print(semicolon.read_text(encoding="utf-8"))
```

В файле комментарий Анны стоит в кавычках: внутри есть символ `;`.

**Ячейка — чтение с тем же разделителем:**

```python
with semicolon.open(encoding="utf-8", newline="") as file:
    semi_rows = list(csv.DictReader(file, delimiter=";"))
print(semi_rows[0]["comment"])
print(len(semi_rows[0]))
```

Если забыть `delimiter=";"`, вся строка склеится в один столбец, а комментарий разъедется на лишние поля. Проверьте это отдельной ячейкой: прочитайте тот же файл с разделителем по умолчанию и напечатайте `len(wrong_row)`.

**Практика 3.1.4.** Создайте `module-3-1/data/incoming.csv` вручную в редакторе, кодировка UTF-8:

```text
name;city;score
Анна;Москва;18
"Борис; младший";Казань;
Вера;Тверь;20
```

У Бориса в городе пустое поле, в имени есть точка с запятой. Загрузите файл через `DictReader` с `delimiter=";"`. Напечатайте имя Бориса и значение `score`. Пустая строка — не ноль: в расчёт среднего её не включают.

```python
incoming = data_dir / "incoming.csv"
with incoming.open(encoding="utf-8", newline="") as file:
    people = list(csv.DictReader(file, delimiter=";"))

print(people[1]["name"], repr(people[1]["score"]))
numbers = [int(row["score"]) for row in people if row["score"] != ""]
print("среднее:", sum(numbers) / len(numbers))
```

**Критерий 3.1.4:** комментарий Анны равен `зачёт; досрочно` и это одно поле. Имя из входящего файла — `Борис; младший`. Среднее по двум заполненным баллам — **19**.

---

## 3.1.5. Кодировка и ошибки загрузки

Файл без BOM в кодировке UTF-8 открывают с `encoding="utf-8"`. Файл из старого Excel на русской Windows часто оказывается в `cp1251`. Неверная кодировка либо портит кириллицу, либо даёт `UnicodeDecodeError`.

**Ячейка — нет файла:**

```python
missing = data_dir / "missing.csv"
try:
    with missing.open(encoding="utf-8", newline="") as file:
        list(csv.reader(file))
except FileNotFoundError as error:
    print(type(error).__name__)
```

**Ячейка — байты и кодировка:**

```python
raw = table.read_bytes()
print(raw[:20])
print(raw.decode("utf-8").splitlines()[0])
```

**Практика 3.1.5.** Прочитайте `notes.csv` с `encoding="cp1251"` внутри `try`. Если исключения нет, напечатайте первую строку и сравните её с чтением в UTF-8. В markdown запишите, совпали ли строки.

**Критерий 3.1.5:** отсутствующий файл даёт `FileNotFoundError`. Первая строка, декодированная из байтов как UTF-8, начинается с `name,score`.

---

## 3.1.6. JSON

JSON хранит списки, словари, числа, строки и логические значения. Его читают целиком: `json.loads` и `json.dumps` работают со строкой, `json.load` и `json.dump` — с файлом. Ключи JSON — строки. В отличие от CSV, число после чтения снова имеет тип `int`, а не `str`.

Возьмите уже загруженный список `rows` из раздела 3.1.1. Если ячейка выполнялась в другом сеансе, соберите список заново из `loaded`.

**Ячейка:**

```python
import json

payload = {"course": "3.1", "students": rows}
json_path = data_dir / "group.json"
json_path.write_text(
    json.dumps(payload, ensure_ascii=False, indent=2),
    encoding="utf-8",
)
restored = json.loads(json_path.read_text(encoding="utf-8"))
print(restored["course"], len(restored["students"]))
print(restored["students"][0]["score"], type(restored["students"][0]["score"]))
```

`ensure_ascii=False` оставляет кириллицу символами, а не последовательностями `\u....`. `indent=2` делает файл читаемым в редакторе.

**Практика 3.1.6.** Запишите тот же словарь через `json.dump` в `module-3-1/data/group-dump.json` и прочитайте его через `json.load`. Сравните словари оператором `==`. Затем сравните тип балла в JSON и тип балла в строке CSV до вызова `int`.

```python
dump_path = data_dir / "group-dump.json"
with dump_path.open("w", encoding="utf-8") as file:
    json.dump(payload, file, ensure_ascii=False, indent=2)
with dump_path.open(encoding="utf-8") as file:
    from_dump = json.load(file)
print(from_dump == restored)
print("json:", type(from_dump["students"][0]["score"]).__name__)
print("csv:", type(loaded[0]["score"]).__name__)
```

**Критерий 3.1.6:** сравнение словарей даёт `True`, в файле имена видны кириллицей, тип балла в JSON — `int`, в CSV — `str`.

---

## 3.1.7. Самопроверка

В конце ноутбука ответьте в markdown:

1. Почему при записи CSV передают `newline=""` и зачем балл из `DictReader` переводить в `int`.
2. Чем опасен `split(",")` по сравнению с `csv.reader`, если в поле есть запятая.
3. Что будет, если файл с разделителем `;` прочитать без `delimiter=";"`.
4. Чем число в CSV отличается от числа в JSON после чтения и чем `json.dumps` отличается от `json.dump`.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | `notes.csv` записан модулем `csv`, без пустых строк между записями | ☐ |
| 2 | `summary.txt`: сумма 64, максимум 20, сдавших 3 | ☐ |
| 3 | Сумма по `csv.reader` совпала со сводкой | ☐ |
| 4 | `notes-semicolon.csv`: комментарий с `;` остался одним полем | ☐ |
| 5 | `incoming.csv`: имя `Борис; младший`, среднее 19 | ☐ |
| 6 | Разобраны `FileNotFoundError` и кодировка | ☐ |
| 7 | `group.json` и `group-dump.json` совпадают, балл в JSON имеет тип `int` | ☐ |
| 8 | Ответы самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| Пустые строки через одну в CSV | В `open` передан `newline=""` |
| Кракозябры | `encoding="utf-8"` и та же кодировка в статусной строке VS Code |
| Все столбцы склеились в один | Для файла с `;` указан `delimiter=";"` |
| `ValueError` на `int("")` | Пустое поле отфильтровано до перевода в число |
| Файл появился не в `module-3-1/data` | `Path.cwd()` и префикс пути |
| `json.dumps` показывает `\u0410...` | Не передан `ensure_ascii=False` |

После занятия слушатель загружает CSV с заголовком, другим разделителем и пустыми полями и сохраняет ту же таблицу в JSON, где числа остаются числами.
