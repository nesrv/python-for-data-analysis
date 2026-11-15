# 3.1. Загрузка CSV

**Объём занятия:** 2 академических часа (~120 минут) активной практики в Visual Studio Code.

**Цель:** прочитать CSV стандартным модулем `csv` и функцией `pandas.read_csv`, учесть кодировку, разделитель и заголовок и проверить, что числа и пустые ячейки загрузились ожидаемо.

**Опора:** окружение `.venv`, ноутбуки из модуля 1. Ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка VS Code — корень курса.

**Итоговые артефакты** (в папке `module-3-1/`):

| Файл | Назначение |
|------|------------|
| `data/scores.csv` | Исходный файл, который слушатель создаёт сам |
| `data/scores_semicolon.csv` | Тот же набор с разделителем `;` |
| `lab31-csv.ipynb` | Ноутбук: чтение через `csv` и `pandas` |
| `data/scores_clean.csv` | Файл, сохранённый после разбора |

---

## Подготовка

Активируйте окружение и установите pandas, если его ещё нет:

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install pandas
```

Создайте ноутбук `module-3-1/lab31-csv.ipynb` и выберите ядро `.venv`.

Первая ячейка — markdown: ФИО, дата, заголовок «3.1 Загрузка CSV».

---

## 3.1.1. Что лежит в CSV

CSV — текстовый файл. Строка таблицы — строка файла. Поля разделяются запятой или другим символом. Первая строка часто содержит имена столбцов. Кодировка в курсе — UTF-8.

Создайте `module-3-1/data/scores.csv` в кодировке UTF-8:

```text
name,group,score,city
Анна,A,18,Москва
Борис,A,15,Казань
Вера,B,20,
Глеб,B,,Тула
```

У Веры пустой город, у Глеба пустой балл. Пустое поле — это не ноль и не строка `"None"`.

**Критерий 3.1.1:** файл открывается в VS Code, в нём четыре строки данных и заголовок, кириллица читается.

---

## 3.1.2. Чтение через csv.reader

`csv.reader` возвращает строки как списки строк. Числа сами в `int` не превращаются.

**Ячейка:**

```python
import csv
from pathlib import Path

path = Path("module-3-1/data/scores.csv")
with path.open(encoding="utf-8", newline="") as f:
    rows = list(csv.reader(f))

header, data = rows[0], rows[1:]
print(header)
print("записей:", len(data))
print("первая строка:", data[0])
print("тип балла:", type(data[0][2]).__name__, repr(data[0][2]))
```

Параметр `newline=""` обязателен для модуля `csv`: модуль сам обрабатывает концы строк.

**Практика 3.1.2.** Соберите список баллов как целых чисел. Пустую ячейку пропускайте, а не превращайте в ноль.

```python
scores = [int(row[2]) for row in data if row[2] != ""]
print(scores, "сумма", sum(scores))
```

**Критерий 3.1.2:** балл в сырой строке — это `str`, в списке `scores` три числа, сумма равна **53**.

---

## 3.1.3. Чтение в словари

`csv.DictReader` берёт заголовок и отдаёт каждую запись словарём. К столбцу обращаются по имени, а не по номеру.

**Ячейка:**

```python
with path.open(encoding="utf-8", newline="") as f:
    records = list(csv.DictReader(f))

print(records[0])
print(records[2]["city"] == "")
print(records[3]["score"] == "")
```

**Практика 3.1.3.** Постройте список словарей только с заполненным баллом. В каждом словаре поля `name` (строка) и `score` (`int`).

```python
ready = [
    {"name": row["name"], "score": int(row["score"])}
    for row in records
    if row["score"] != ""
]
print(ready)
```

**Критерий 3.1.3:** в `ready` три человека, Глеба нет, у Анны балл `18` и тип `int`.

---

## 3.1.4. Кодировка и разделитель

Файл в UTF-8, открытый как `cp1251`, испортит кириллицу или выбросит `UnicodeDecodeError`. Разделитель не всегда запятая: в таблицах, сохранённых из русской Excel, часто стоит `;`.

Создайте `module-3-1/data/scores_semicolon.csv`:

```text
name;group;score;city
Анна;A;18;Москва
Борис;A;15;Казань
Вера;B;20;
Глеб;B;;Тула
```

**Ячейка — неверный разделитель:**

```python
semi = Path("module-3-1/data/scores_semicolon.csv")
with semi.open(encoding="utf-8", newline="") as f:
    wrong = list(csv.DictReader(f))
print(list(wrong[0].keys()))
```

Без `delimiter=";"` вся строка попадает в один ключ.

**Ячейка — верный разделитель:**

```python
with semi.open(encoding="utf-8", newline="") as f:
    fixed = list(csv.DictReader(f, delimiter=";"))
print(fixed[0]["name"], fixed[0]["score"])
```

**Практика 3.1.4.** Прочитайте `scores.csv` с `encoding="utf-8"` и выведите имена. В markdown напишите, какой параметр меняют, если вместо запятой в файле точка с запятой.

**Критерий 3.1.4:** при `delimiter=";"` имя первой записи — `Анна`, балл — строка `"18"`.

---

## 3.1.5. Загрузка через pandas

Дальше по курсу таблицы удобнее держать в `DataFrame`. `read_csv` сам отделяет заголовок и умеет превратить пустые поля в пропуски.

**Ячейка:**

```python
import pandas as pd

frame = pd.read_csv(path, encoding="utf-8")
print(frame)
print(frame.dtypes)
print("пропуски в score:", int(frame["score"].isna().sum()))
```

Пустой балл Глеба становится `NaN`, а не пустой строкой. Город Веры — тоже пропуск.

**Ячейка — другой разделитель:**

```python
semi_frame = pd.read_csv(semi, sep=";", encoding="utf-8")
print(semi_frame["name"].tolist())
```

**Практика 3.1.5.** Оставьте строки, где балл заполнен, и приведите столбец `score` к целому типу:

```python
clean = frame.dropna(subset=["score"]).copy()
clean["score"] = clean["score"].astype(int)
print(clean[["name", "score"]])
print("сумма", int(clean["score"].sum()))
```

**Критерий 3.1.5:** в `clean` три строки, сумма баллов **53**, кириллица в столбце `name` на месте.

---

## 3.1.6. Запись проверенной таблицы

Результат разбора сохраняют обратно в CSV, чтобы следующий шаг курса читал уже понятный файл.

**Ячейка:**

```python
out = Path("module-3-1/data/scores_clean.csv")
clean.to_csv(out, index=False, encoding="utf-8")
print(out.read_text(encoding="utf-8"))
```

`index=False` не записывает номер строки отдельным столбцом.

Прочитайте файл ещё раз и сверьте сумму:

```python
check = pd.read_csv(out, encoding="utf-8")
print(check["score"].sum())
```

**Критерий 3.1.6:** в `scores_clean.csv` есть заголовок `name,group,score,city`, нет Глеба, повторная сумма равна **53**.

---

## 3.1.7. Самопроверка

В конце ноутбука ответьте в markdown:

1. Почему балл из `csv.reader` — строка, даже если в файле написаны цифры.
2. Чем пустое поле CSV отличается от нуля.
3. Когда нужен параметр `delimiter` у `csv` и параметр `sep` у `read_csv`.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | `data/scores.csv` в UTF-8, четыре записи | ☐ |
| 2 | `csv.reader`: балл прочитан как строка, сумма заполненных баллов 53 | ☐ |
| 3 | `DictReader`: список `ready` без Глеба | ☐ |
| 4 | Файл с `;` читается только с явным разделителем | ☐ |
| 5 | `pandas.read_csv`: виден пропуск в `score` | ☐ |
| 6 | `data/scores_clean.csv` читается повторно, сумма 53 | ☐ |
| 7 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| Кракозябры вместо имён | `encoding="utf-8"` и при чтении, и при записи |
| Вся строка в одном столбце | В файле `;`, а читатель ждёт запятую |
| `ValueError` на `int("")` | Пустой балл нужно отфильтровать до преобразования |
| Лишний столбец `Unnamed: 0` | В `to_csv` не передан `index=False` |
| `FileNotFoundError` | Ноутбук запущен из корня курса, путь `module-3-1/data/...` |
| `ModuleNotFoundError: pandas` | `python -m pip install pandas` в активированном `.venv`, ядро ноутбука — тот же интерпретатор |

После занятия слушатель открывает CSV и проверяет три вещи: кодировку, разделитель и то, как в таблице отмечены пустые значения.
