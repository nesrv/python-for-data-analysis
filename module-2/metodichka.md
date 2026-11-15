# Модуль 2. Основы Python

**Объём занятия:** 2 академических часа (~120 минут) **активной практики** в Visual Studio Code.

**Цель:** уверенно пользоваться типами и объектами Python, импортами, чтением и записью файлов, простыми графиками, ветвлением, отладчиком VS Code и профилированием.

**Опора:** окружение `.venv` и Jupyter из модуля 1. Интерпретатор VS Code — `./.venv/Scripts/python.exe`.

**Итоговые артефакты** (в папке `module-2/`):

| Файл | Назначение |
|------|------------|
| `lab02-basics.ipynb` | Ноутбук: типы, импорт, ветвление, график |
| `data/notes.csv` | Файл, который слушатель создаёт и читает |
| `data/summary.txt` | Результат записи из Python |
| `figures/simple.png` | Сохранённый график matplotlib |
| `debug_demo.py` | Скрипт с точкой останова в VS Code |
| `profile_demo.py` | Скрипт для `cProfile` |

Преподаватель проверяет вывод ячеек, наличие файлов и то, что график и профиль получены из `.venv`.

---

## Подготовка (до блока A)

В корне проекта, с активным `.venv`:

```powershell
.\.venv\Scripts\Activate.ps1
pip install matplotlib
mkdir module-2\data, module-2\figures -ErrorAction SilentlyContinue
```

Создайте `module-2/lab02-basics.ipynb` и выберите ядро из `.venv`.

---

## Блок A. Типы данных и объекты

В Python всё — объект: у значения есть тип, идентичность и методы.

**Ячейка A1 — встроенные типы:**

```python
values = [42, 3.14, "текст", True, None, (1, 2), [1, 2], {"a": 1}, {1, 2}]
for v in values:
    print(type(v).__name__, "->", repr(v))
```

**Ячейка A2 — изменяемость:**

```python
nums = [1, 2, 3]
alias = nums
alias.append(4)
print("общий список:", nums)

pair = (1, 2)
# pair[0] = 9  # TypeError: кортеж неизменяем
```

**Ячейка A3 — строки и срезы:**

```python
s = "Python для данных"
print(s[:6], s.lower(), s.split())
print(f"длина {len(s)}, символ 0: {s[0]!r}")
```

**Критерий A:** в выводе есть `int`, `float`, `str`, `bool`, `NoneType`, `tuple`, `list`, `dict`, `set`; после `append` исходный список тоже содержит `4`.

**Markdown-ячейка:** одним предложением — чем список отличается от кортежа.

---

## Блок B. Загрузка пакетов и пространства имён

**Ячейка B1:**

```python
import math
from pathlib import Path
import matplotlib.pyplot as plt

print("math.pi =", round(math.pi, 4))
print("Path cwd =", Path.cwd().name)
print("pyplot =", plt.__name__)
```

**Ячейка B2 — имя не «протекает» без импорта:**

```python
import statistics as stats
print("среднее", stats.mean([2, 4, 4, 4, 5, 5, 7, 9]))
```

**Практика:** в новой ячейке импортируйте только функцию `sqrt` из `math` и посчитайте `sqrt(16)`. Не используйте `from math import *`.

**Критерий B:** три способа импорта (`import`, `from … import`, `import … as`) есть в ноутбуке и дают вывод.

---

## Блок C. Чтение и запись данных

Работаем с текстовыми файлами через `pathlib` и модуль `csv`.

**Скрипт или ячейка C1 — запись CSV** `module-2/data/notes.csv`:

```python
import csv
from pathlib import Path

path = Path("module-2/data/notes.csv")
path.parent.mkdir(parents=True, exist_ok=True)

rows = [
    {"name": "Анна", "score": 18},
    {"name": "Борис", "score": 15},
    {"name": "Вера", "score": 20},
]
with path.open("w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "score"])
    writer.writeheader()
    writer.writerows(rows)
print("записано", path.resolve())
```

Запускайте ячейку из **корня проекта** (рабочая папка VS Code). Если ноутбук лежит в `module-2` и `Path.cwd()` — эта папка, используйте `Path("data/notes.csv")`.

**Ячейка C2 — чтение и сводка:**

```python
with path.open(encoding="utf-8", newline="") as f:
    loaded = list(csv.DictReader(f))

scores = [int(row["score"]) for row in loaded]
lines = [
    f"записей: {len(loaded)}",
    f"сумма баллов: {sum(scores)}",
    f"максимум: {max(scores)}",
]
out = path.with_name("summary.txt")
out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(out.read_text(encoding="utf-8"))
```

**Критерий C:** существуют `notes.csv` и `summary.txt`; сумма баллов в тексте равна **53**.

---

## Блок D. Простое рисование графиков

```python
import matplotlib.pyplot as plt
from pathlib import Path

names = [row["name"] for row in loaded]
scores = [int(row["score"]) for row in loaded]

fig, ax = plt.subplots(figsize=(6, 3))
ax.bar(names, scores, color="#2F6FED")
ax.set_title("Баллы")
ax.set_ylabel("score")
fig.tight_layout()

fig_path = Path("module-2/figures/simple.png")
fig_path.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(fig_path, dpi=120)
plt.show()
print("график:", fig_path.resolve())
```

В VS Code график появляется под ячейкой. Файл `simple.png` нужен как артефакт.

**Критерий D:** три столбца, подписи — имена из CSV, файл сохранён.

---

## Блок E. Управление потоком и ветвление

**Ячейка E1:**

```python
def grade(score: int) -> str:
    if score >= 18:
        return "зачёт с отличием"
    if score >= 12:
        return "зачёт"
    return "нужна доработка"

for row in loaded:
    s = int(row["score"])
    print(row["name"], s, "->", grade(s))
```

**Ячейка E2 — цикл и пропуск:**

```python
total = 0
for n in range(1, 11):
    if n % 2 == 0:
        continue
    total += n
print("сумма нечётных 1..10 =", total)  # 25
```

**Критерий E:** для баллов 18, 15 и 20 выводятся «зачёт с отличием», «зачёт», «зачёт с отличием»; сумма нечётных равна 25.

---

## Блок F. Отладка в VS Code

Создайте `module-2/debug_demo.py`:

```python
def grade(score: int) -> str:
    if score >= 18:
        label = "зачёт с отличием"
    elif score >= 12:
        label = "зачёт"
    else:
        label = "нужна доработка"
    return label


def main():
    scores = [18, 15, 9]
    for score in scores:
        result = grade(score)
        print(score, result)


if __name__ == "__main__":
    main()
```

1. Щёлкните слева от строки `result = grade(score)` — красная точка останова.
2. Откройте **Run and Debug** (`Ctrl+Shift+D`) → **Python File**. Интерпретатор — `.venv`.
3. На остановке в панели **Variables** посмотрите `score`. Шаг **Step Over** (`F10`), затем **Continue** (`F5`).
4. Убедитесь, что в консоли отладки три строки.

**Критерий F:** точка останова срабатывает на каждой итерации; для `9` в переменной `label` после шага внутрь функции — «нужна доработка».

---

## Блок G. Профилирование

Создайте `module-2/profile_demo.py`:

```python
def slow_sum(n: int) -> int:
    total = 0
    for i in range(n):
        total += i
    return total


def main():
    return slow_sum(200_000) + slow_sum(100_000)


if __name__ == "__main__":
    print(main())
```

В терминале с `.venv`, из корня проекта:

```powershell
python -m cProfile -s cumtime module-2\profile_demo.py
```

В выводе найдите строку `slow_sum`. В ноутбуке добавьте markdown: сколько вызовов `slow_sum` (ожидается **2**) и что сортировка `-s cumtime` показывает функции с наибольшим накопленным временем сверху.

Короткий замер в ячейке:

```python
import timeit
print(timeit.timeit("sum(range(10_000))", number=500))
```

**Критерий G:** профиль запускается без ошибки, в таблице есть `slow_sum`, скрипт печатает сумму.

---

## Чеклист слушателя

| № | Действие | Готово |
|---|----------|--------|
| 1 | `lab02-basics.ipynb`: типы, импорты, ветвление, график с выводом | ☐ |
| 2 | `data/notes.csv` и `data/summary.txt` (сумма 53) | ☐ |
| 3 | `figures/simple.png` | ☐ |
| 4 | Отладчик останавливается в `debug_demo.py` | ☐ |
| 5 | `python -m cProfile` по `profile_demo.py` показывает `slow_sum` | ☐ |

## Типовые проблемы

| Симптом | Действие |
|---------|----------|
| `No module named matplotlib` | Активировать `.venv`, `pip install matplotlib`, ядро ноутбука — тот же интерпретатор |
| CSV пишется «не туда» | Сверить `Path.cwd()` с корнем проекта и поправить относительный путь |
| Кириллица в CSV «кракозябрами» | Открывать и писать с `encoding="utf-8"` |
| Отладчик использует системный Python | **Python: Select Interpreter** → `.venv` |
| График пустой | Вызвать `plt.show()` или выполнить ячейку до конца; проверить, что `scores` не пустой |

После чеклиста можно переходить к **Модулю 3** (CSV, СУБД, очистка данных): здесь уже есть свой небольшой CSV и столбчатая диаграмма.
