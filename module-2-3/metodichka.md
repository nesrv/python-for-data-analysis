# 2.3. Чтение и запись данных

**Цель:** читать и записывать текст методами файлового объекта, сохранять данные в JSON и pickle, не терять кодировку и закрывать файлы через `with`. Загрузка CSV вынесена в раздел 3.1.

**Опора:** окружение `.venv` и ноутбуки из модуля 1. Ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка VS Code — корень курса.

**Итоговые артефакты** (в папке `module-2-3/`):

| Файл | Назначение |
|------|------------|
| `lab23-io.ipynb` | Ноутбук со всеми разделами и сохранённым выводом |
| `data/notes.txt` | Текстовый файл, записанный из Python |
| `data/lines.txt` | Файл, собранный через `write` и `print` |
| `data/group.json` | Словарь с оценками в JSON |
| `data/group.pickle` | Тот же словарь в формате pickle |

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

## 2.3.4. read, readline, readlines, write и print

У открытого текстового файла есть методы чтения и записи. `write` и `print` сами перевод строки не подставляют одинаково: `write` пишет ровно переданную строку, `print` по умолчанию добавляет `\n` в конец.

**Ячейка — запись:**

```python
lines_path = data_dir / "lines.txt"
with lines_path.open("w", encoding="utf-8") as file:
    file.write("первая\n")
    file.write("вторая\n")
    print("третья", file=file)
```

`print(..., file=file)` направляет текст в файл, а не в ячейку ноутбука.

**Ячейка — три способа прочитать:**

```python
with lines_path.open(encoding="utf-8") as file:
    whole = file.read()
print("read:", repr(whole))

with lines_path.open(encoding="utf-8") as file:
    first = file.readline()
    second = file.readline()
print("readline:", repr(first), repr(second))

with lines_path.open(encoding="utf-8") as file:
    rows = file.readlines()
print("readlines:", rows, "строк:", len(rows))
```

`read` возвращает весь оставшийся текст одной строкой. `readline` — одну строку вместе с `\n` в конце; пустая строка `""` означает конец файла. `readlines` — список всех строк, тоже с `\n`. После `read` указатель стоит в конце: повторный `read` в том же `with` вернёт `""`. Поэтому каждый пример открывает файл заново.

**Практика 2.3.4.** Допишите в `lines.txt` строку `четвёртая` через `print` в режиме `"a"`. Прочитайте файл через `readline` в цикле, пока строка не пустая, и напечатайте число строк без символа перевода строки (`strip`).

```python
with lines_path.open("a", encoding="utf-8") as file:
    print("четвёртая", file=file)

count = 0
with lines_path.open(encoding="utf-8") as file:
    while True:
        line = file.readline()
        if line == "":
            break
        print(line.strip())
        count += 1
print("всего:", count)
```

**Критерий 2.3.4:** `readlines` сначала даёт три элемента, после практики в файле четыре строки, последняя — `четвёртая`.

---

## 2.3.5. JSON

JSON хранит списки, словари, числа, строки и логические значения. Его удобно читать целиком: `json.loads` / `json.dumps` или `json.load` / `json.dump` для файла. Ключи JSON — строки.

**Ячейка:**

```python
import json

students = [
    {"name": "Анна", "score": 18},
    {"name": "Борис", "score": 15},
    {"name": "Вера", "score": 20},
    {"name": "Глеб", "score": 11},
]
payload = {"course": "2.3", "students": students}
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

Число в JSON после чтения снова имеет тип `int`.

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

**Практика 2.3.6.** Откройте `notes.txt` в VS Code и убедитесь, что кодировка UTF-8. Если редактор предлагает другую, переключите её и пересохраните файл только если текст уже отображается верно.

**Критерий 2.3.6:** отсутствующий файл даёт `FileNotFoundError`; первая строка, прочитанная из байтов как UTF-8, равна `Анна: 18`.

---

## 2.3.7. Pickle

Модуль `pickle` сохраняет объект Python в двоичный файл и восстанавливает его обратно: словарь, список, число, строку. Файл открывают в режиме `"wb"` при записи и `"rb"` при чтении. Кодировку для pickle не указывают: это не текст, в редакторе он выглядит как набор байтов.

Pickle выполняют только для своих файлов. Загрузка чужого `.pickle` может запустить код из файла. В курсе так не делают.

**Ячейка:**

```python
import pickle

pickle_path = data_dir / "group.pickle"
with pickle_path.open("wb") as file:
    pickle.dump(payload, file)

with pickle_path.open("rb") as file:
    from_pickle = pickle.load(file)

print(from_pickle == payload)
print(from_pickle["students"][0]["name"], type(from_pickle["students"][0]["score"]))
print("размер, байт:", pickle_path.stat().st_size)
```

**Практика 2.3.7.** Сохраните в тот же каталог список `[1, "текст", True]` в файл `values.pickle` и прочитайте его. Напечатайте типы трёх элементов.

**Критерий 2.3.7:** словарь из pickle совпадает с `payload`, балл имеет тип `int`, у трёх элементов списка типы `int`, `str` и `bool`.

---

## 2.3.8. Самопроверка

В конце ноутбука ответьте в markdown:

1. Чем `read` отличается от `readline` и от `readlines`.
2. Чем `file.write("строка")` отличается от `print("строка", file=file)`.
3. Чем файл pickle отличается от JSON и почему нельзя загружать чужой `.pickle`.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | Папка `module-2-3/data` создана из ноутбука | ☐ |
| 2 | `notes.txt`: четыре строки, кириллица на месте | ☐ |
| 3 | `log.txt` и проверка режима `"x"` | ☐ |
| 4 | `lines.txt`: четыре строки, последняя прочитана через `readline` | ☐ |
| 5 | `group.json` и `group-dump.json`, словари равны | ☐ |
| 6 | `group.pickle` и `values.pickle` загружаются обратно | ☐ |
| 7 | Разобран `FileNotFoundError` | ☐ |
| 8 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| Файл появляется не в `module-2-3/data` | `Path.cwd()` и префикс пути |
| Кракозябры в блокноте Windows | Файл записан без `encoding="utf-8"` |
| `FileNotFoundError` при чтении только что записанного | Путь чтения и путь записи различаются |
| `json.dumps` показывает `\u0410...` | Не передан `ensure_ascii=False` |
| `TypeError` у `pickle.dump` | Файл открыт как текст (`"w"`), нужен `"wb"` |
| `UnpicklingError` | Файл записан не через `pickle` или обрезан |

После занятия слушатель читает текст по строкам и целиком, пишет через `write` и `print` и сохраняет объект в JSON и pickle. Таблицы CSV разбираются в разделе 3.1.
