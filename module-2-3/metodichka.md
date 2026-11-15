# 2.3. Чтение и запись данных

**Формат:** активная практика в Visual Studio Code.

**Цель:** читать и записывать текст, CSV и JSON через `pathlib`, не терять кодировку и закрывать файлы через `with`.

**Опора:** окружение `.venv` и ноутбуки из модуля 1. Ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка VS Code — корень курса.

**Итоговые артефакты** (в папке `module-2-3/`):

| Файл | Назначение |
|------|------------|
| `lab23-io.ipynb` | Ноутбук со всеми разделами и сохранённым выводом |
| `data/notes.txt` | Текстовый файл, записанный из Python |
| `data/notes.csv` | Таблица оценок |
| `data/summary.txt` | Сводка, посчитанная по CSV |
| `data/group.json` | Те же данные в JSON |

---

## Подготовка

Откройте корень курса в VS Code, активируйте окружение и создайте ноутбук `module-2-3/lab23-io.ipynb`. Выберите ядро `.venv`.

```powershell
.\.venv\Scripts\Activate.ps1
```

Первая ячейка — markdown: ФИО, дата, заголовок «2.3 Чтение и запись данных».

Пути в ячейках заданы от корня курса (`module-2-3/data/...`). Если `Path.cwd()` — сама папка `module-2-3`, уберите префикс `module-2-3/` и оставьте `data/...`.

---

## 2.3.1. Путь к файлу

Файл на диске адресуют путём. `pathlib.Path` собирает путь из частей, создаёт папки и не зависит от того, какой в системе разделитель каталогов.

**Ячейка:**

```python
from pathlib import Path

data_dir = Path("module-2-3") / "data"
data_dir.mkdir(parents=True, exist_ok=True)

notes = data_dir / "notes.txt"
print("каталог:", data_dir.resolve())
print("файл:", notes)
print("существует:", notes.exists())
print("родитель:", notes.parent.name, "имя:", notes.name, "суффикс:", notes.suffix)
```

`mkdir(..., exist_ok=True)` не падает, если папка уже есть. `parents=True` создаёт и промежуточные каталоги.

**Практика 2.3.1.** Напечатайте текущий каталог через `Path.cwd()` и одной фразой в markdown запишите, от какой папки вы будете строить пути в этом ноутбуке.

**Критерий 2.3.1:** папка `module-2-3/data` есть на диске, у пути к `notes.txt` суффикс `.txt`.

---

## 2.3.2. Текст: запись и чтение

Текст в курсе пишут и читают в кодировке UTF-8. Так кириллица одинаково открывается в VS Code и в Python.

**Ячейка — запись целиком:**

```python
notes.write_text("Анна: 18\nБорис: 15\nВера: 20\n", encoding="utf-8")
print(notes.read_text(encoding="utf-8"))
```

`write_text` создаёт файл или полностью заменяет его содержимое.

**Ячейка — по строкам:**

```python
lines = notes.read_text(encoding="utf-8").splitlines()
print(len(lines), lines[0])
```

`splitlines()` убирает символы перевода строки. Пустая строка в конце файла отдельным элементом не становится, если после последней строки ничего нет.

**Практика 2.3.2.** Добавьте в файл четвёртую строку `Глеб: 11`, не стирая уже записанные три. Прочитайте файл и напечатайте число строк.

Подсказка: режим дозаписи — `"a"`, а не повторный `write_text`.

```python
with notes.open("a", encoding="utf-8") as file:
    file.write("Глеб: 11\n")
print(len(notes.read_text(encoding="utf-8").splitlines()))
```

**Критерий 2.3.2:** в `notes.txt` четыре строки, первая — `Анна: 18`, последняя — `Глеб: 11`.

---

## 2.3.3. Режим открытия и `with`

`open` возвращает файловый объект. Его нужно закрыть: иначе буфер может не дописаться на диск. Конструкция `with` закрывает файл и при обычном выходе, и при исключении.

| Режим | Действие |
|-------|----------|
| `"r"` | Чтение. Файл должен существовать |
| `"w"` | Запись с нуля. Содержимое стирается |
| `"a"` | Дозапись в конец |
| `"x"` | Создание только нового файла. Если файл есть — ошибка |

Для текста к режиму добавляют кодировку: `encoding="utf-8"`.

**Ячейка:**

```python
log_path = data_dir / "log.txt"
with log_path.open("w", encoding="utf-8") as file:
    file.write("старт\n")

with log_path.open("a", encoding="utf-8") as file:
    file.write("ещё строка\n")

with log_path.open("r", encoding="utf-8") as file:
    print(file.read())
```

**Ячейка — файл уже есть:**

```python
try:
    with log_path.open("x", encoding="utf-8") as file:
        file.write("не запишется\n")
except FileExistsError as error:
    print(type(error).__name__)
```

**Критерий 2.3.3:** в `log.txt` две строки, `open("x")` по существующему файлу даёт `FileExistsError`.

---

## 2.3.4. CSV

CSV — текст, в котором поля разделены запятой, а первая строка часто содержит имена столбцов. Модуль `csv` учитывает кавычки и перевод строки внутри поля. В Windows при записи передают `newline=""`, иначе между строками появляется лишняя пустая строка.

**Ячейка — запись:**

```python
import csv

table = data_dir / "notes.csv"
rows = [
    {"name": "Анна", "score": 18},
    {"name": "Борис", "score": 15},
    {"name": "Вера", "score": 20},
    {"name": "Глеб", "score": 11},
]
with table.open("w", encoding="utf-8", newline="") as file:
    writer = csv.DictWriter(file, fieldnames=["name", "score"])
    writer.writeheader()
    writer.writerows(rows)
print(table.read_text(encoding="utf-8"))
```

**Ячейка — чтение и сводка:**

```python
with table.open(encoding="utf-8", newline="") as file:
    loaded = list(csv.DictReader(file))

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

`DictReader` отдаёт каждую строку словарём. Числа из CSV приходят строками, поэтому балл переводят через `int`.

**Практика 2.3.4.** Допишите в сводку строку `сдавших: N`, где N — число баллов `>= 12`.

**Критерий 2.3.4:** сумма баллов **64**, максимум **20**, сдавших **3**.

---

## 2.3.5. JSON

JSON хранит списки, словари, числа, строки и логические значения. Его удобно читать целиком: `json.loads` / `json.dumps` или `json.load` / `json.dump` для файла. Ключи JSON — строки.

**Ячейка:**

```python
import json

payload = {"course": "2.3", "students": rows}
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

Число в JSON после чтения снова имеет тип `int`, в отличие от CSV.

**Практика 2.3.5.** Запишите тот же словарь через `json.dump` в файл `module-2-3/data/group-dump.json` и прочитайте его через `json.load`. Сравните два словаря оператором `==`.

```python
dump_path = data_dir / "group-dump.json"
with dump_path.open("w", encoding="utf-8") as file:
    json.dump(payload, file, ensure_ascii=False, indent=2)
with dump_path.open(encoding="utf-8") as file:
    from_dump = json.load(file)
print(from_dump == restored)
```

**Критерий 2.3.5:** сравнение даёт `True`, в файле видны имена кириллицей.

---

## 2.3.6. Ошибки чтения

**Ячейка — нет файла:**

```python
missing = data_dir / "missing.txt"
try:
    missing.read_text(encoding="utf-8")
except FileNotFoundError as error:
    print(type(error).__name__, error.filename)
```

**Ячейка — неверная кодировка.** Файл `notes.txt` записан в UTF-8. Чтение как `cp1251` может не упасть, но текст будет другим, либо дать `UnicodeDecodeError` на байтах, которых в этой кодировке нет. Проверьте оба исхода так:

```python
raw = notes.read_bytes()
print("первые байты:", raw[:12])
print("как utf-8:", raw.decode("utf-8").splitlines()[0])
```

Байты файла и строка — разные объекты. `read_bytes` не применяет кодировку. Для текста курса используйте UTF-8 и в Python, и в статусной строке VS Code (справа внизу при открытии файла).

**Практика 2.3.6.** Откройте `notes.csv` в VS Code и убедитесь, что кодировка UTF-8. Если редактор предлагает другую, переключите её и пересохраните файл только если текст уже отображается верно.

**Критерий 2.3.6:** отсутствующий файл даёт `FileNotFoundError`; первая строка, прочитанная из байтов как UTF-8, равна `Анна: 18`.

---

## 2.3.7. Самопроверка

В конце ноутбука ответьте в markdown:

1. Чем `write_text` отличается от режима `"a"`.
2. Почему при записи CSV передают `newline=""` и зачем балл из `DictReader` переводить в `int`.
3. Чем число в CSV отличается от числа в JSON после чтения.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | Папка `module-2-3/data` создана из ноутбука | ☐ |
| 2 | `notes.txt`: четыре строки, кириллица на месте | ☐ |
| 3 | `log.txt` и проверка режима `"x"` | ☐ |
| 4 | `notes.csv` и `summary.txt`: сумма 64, сдавших 3 | ☐ |
| 5 | `group.json` и `group-dump.json`, словари равны | ☐ |
| 6 | Разобран `FileNotFoundError` | ☐ |
| 7 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| Файл появляется не в `module-2-3/data` | `Path.cwd()` и префикс пути |
| Пустые строки через одну в CSV | В `open` для CSV не передан `newline=""` |
| Кракозябры в блокноте Windows | Файл записан без `encoding="utf-8"` |
| `FileNotFoundError` при чтении только что записанного | Путь чтения и путь записи различаются |
| `json.dumps` показывает `\u0410...` | Не передан `ensure_ascii=False` |

После занятия слушатель сам сохраняет таблицу оценок в CSV и JSON и читает её обратно тем же окружением.
