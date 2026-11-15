# Модуль 1. Введение и настройка рабочей среды

**Формат:** активная практика в Visual Studio Code.

**Цель:** каждый слушатель сам настраивает окружение курса: виртуальное окружение Python, IPython, Jupyter (ноутбуки в VS Code) и сдаёт минимальный набор артефактов.

**Итоговые артефакты** (в папке `module-1/` в корне проекта):

| Файл | Назначение |
|------|------------|
| `practice-env-check.txt` | Текстовый отчёт о версиях и пути к интерпретатору |
| `practice-ipython-log.txt` | Сохранённый вывод сессии IPython |
| `lab01-environment.ipynb` | Ноутбук с выполненными ячейками и markdown-описанием среды |

Преподаватель проверяет наличие файлов и корректность путей (интерпретатор из `.venv`).

При работе на удалённом АРМ (см. `help.md` в корне курса) шаги те же; терминал — **Терминал** → **Создать терминал** (клавиши **Ctrl+`**).

---

## Подготовка

### Что должно быть установлено

1. **Python 3.10+** — [python.org/downloads](https://www.python.org/downloads/) (галочка **Add Python to PATH**).
2. **Visual Studio Code** — [code.visualstudio.com](https://code.visualstudio.com/).

**Практика 0.1**: откройте VS Code, терминал, выполните:

```powershell
python --version
```

Зафиксируйте версию — она попадёт в `practice-env-check.txt`.

### Расширения VS Code

`Ctrl+Shift+X`, установить:

- **Python** (Microsoft)
- **Jupyter** (Microsoft)

Перезапустите VS Code при необходимости.

**Практика 0.2**: **Файл** → **Открыть папку** → каталог курса (например `IT-cloud`). Создайте подпапку `module-1`, если её ещё нет. В проводнике слева должны быть видны `program.md`, `module-1` и т.д.

**Практика 0.3**: в терминале VS Code:

```powershell
code --version
```

Если команда не найдена — это не критично; главное, что редактор открыт с нужной папкой.

---

## Блок A. Виртуальное окружение

Виртуальное окружение изолирует пакеты курса от системного Python.

### Теория (устно)

Один проект — своё окружение в `.venv`. VS Code должен использовать **этот** `python.exe` и в терминале, и в ноутбуках.

### Практика A.1 — создание окружения

В терминале VS Code (корень проекта):

```powershell
python -m venv .venv
```

Убедитесь, что появилась папка `.venv` (её можно скрыть в `.gitignore` позже).

### Практика A.2 — активация

**PowerShell:**

```powershell
.\.venv\Scripts\Activate.ps1
```

Префикс `(.venv)` в начале строки — признак успеха.

Если ошибка политики выполнения:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Повторите активацию. Альтернатива — **cmd**: `.venv\Scripts\activate.bat`.

### Практика A.3 — интерпретатор в VS Code

1. `Ctrl+Shift+P` → **Python: Select Interpreter**.
2. Выбрать `./.venv/Scripts/python.exe` (**Recommended**).

В статусной строке внизу отображается выбранный Python.

### Практика A.4 — отчёт `practice-env-check.txt`

С **активным** `.venv` выполните и **сохраните полный вывод** в файл `module-1/practice-env-check.txt`:

```powershell
python --version
python -c "import sys; print(sys.executable)"
where python
pip --version
```

**Критерий приёмки A:** в файле путь к `python.exe` содержит `\IT-cloud\.venv\` (или ваш корень проекта + `\.venv\`).

### Самопроверка A

Откройте новый терминал (`+` на панели терминала). Если префикса `(.venv)` нет — снова активируйте окружение. Запустите:

```powershell
python -c "print('venv ok')"
```

---

## Блок B. IPython

IPython — улучшенная интерактивная оболочка: подсказки, история, магические команды.

### Практика B.1 — установка

```powershell
python -m pip install --upgrade pip
pip install ipython
ipython --version
```

Добавьте строку с версией IPython в конец `practice-env-check.txt`.

### Практика B.2 — сессия в терминале

```powershell
ipython
```

Внутри IPython выполните **по порядку** (фиксируйте вывод для файла `practice-ipython-log.txt`):

```python
2 ** 10
name = "course"
name.upper()
```

Магические команды:

```python
%who
%timeit sum(range(1000))
```

Подсказка по объекту:

```python
len?
```

Выйти: `exit` или `Ctrl+D`.

**Практика B.3 — сохранить лог**

В PowerShell удобно один раз перезаписать лог так (из корня проекта, `.venv` активен):

```powershell
ipython -c "print(2**10); name='course'; print(name.upper());" | Out-File -Encoding utf8 module-1\practice-ipython-log.txt
```

Затем **допишите вручную** в тот же файл две строки вывода из интерактива: результат `%timeit ...` и фрагмент справки `len?` (скопируйте из терминала).

**Критерий приёмки B:** в логе есть `1024`, `COURSE`, замер `timeit`.

### Дополнительно в VS Code

`Ctrl+Shift+P` → **Python: Start REPL** — обычный REPL выбранного интерпретатора; для полного IPython надёжнее команда `ipython` в терминале.

---

## Блок C. Jupyter в VS Code

### Практика C.1 — пакеты

```powershell
pip install notebook jupyterlab ipykernel
jupyter --version
```

Кратко зафиксируйте вывод `jupyter --version` в `practice-env-check.txt`.

Опционально — понятное имя ядра:

```powershell
python -m ipykernel install --user --name=it-cloud --display-name "Python (IT-cloud)"
```

### Практика C.2 — ноутбук `lab01-environment.ipynb`

1. **Файл** → **Новый файл** → сохранить как `module-1/lab01-environment.ipynb`.
2. Вверху справа выбрать ядро: `./.venv/.../python.exe` или **Python (IT-cloud)**.

**Ячейка Markdown (первая):** заголовок «Модуль 1. Моя среда», ФИО, дата.

**Ячейка кода 1:**

```python
import sys
import platform
print("executable:", sys.executable)
print("platform:", platform.platform())
print("python:", sys.version.split()[0])
```

Выполнить: **Run** или `Shift+Enter`.

**Ячейка кода 2:**

```python
# Арифметика и типы — проверка, что ядро живое
a, b = 14, 3
print("деление:", a / b, "остаток:", a % b)
type(a / b), type(a % b)
```

**Ячейка кода 3:**

```python
import IPython
print("IPython", IPython.__version__)
```

**Ячейка Markdown (итог):** одно предложение: «Интерпретатор из .venv: да/нет» — по фактическому пути из ячейки 1.

**Критерий приёмки C:** ноутбук сохранён, у всех ячеек кода есть вывод; `sys.executable` указывает на `.venv`.

### Практика C.3 — работа с ячейками

- Добавить ячейку **сверху** (Markdown): оглавление из 3 пунктов.
- Изменить числа в ячейке 2, **перезапустить только эту ячейку**.
- **Restart Kernel** и **Run All** — убедиться, что вывод воспроизводится.

### Практика C.4 — Jupyter в браузере (демо или по желанию)

```powershell
jupyter lab
```

Открыть созданный `lab01-environment.ipynb`, выполнить одну ячейку, закрыть вкладку. Остановить сервер в терминале: `Ctrl+C`, подтвердить завершение.

На занятии **основной режим — Jupyter в VS Code**; браузер — запасной вариант.

---

## Блок D. Самостоятельное мини-задание

**Задание D1.** В том же `lab01-environment.ipynb` добавьте ячейку кода:

```python
def env_summary():
    import sys, os
    root = os.path.abspath(os.path.join(os.path.dirname(__file__) if "__file__" in dir() else ".", ".."))
    # в ноутбуке __file__ часто отсутствует — используем текущую директорию:
    cwd = os.getcwd()
    in_venv = ".venv" in sys.executable.replace("/", "\\")
    return {
        "cwd": cwd,
        "executable": sys.executable,
        "in_venv": in_venv,
    }

env_summary()
```

Если `__file__` вызывает путаницу — упростите до:

```python
import sys, os
{
    "cwd": os.getcwd(),
    "executable": sys.executable,
    "in_venv": ".venv" in sys.executable,
}
```

**Задание D2.** Markdown-ячейка: ответьте (2–3 предложения), зачем изолировать пакеты в venv при работе над несколькими проектами.

**Задание D3.** Создайте файл `module-1/hello.py`:

```python
def main():
    print("Hello from module-1")

if __name__ == "__main__":
    main()
```

Запуск из терминала (`.venv` активен):

```powershell
python module-1\hello.py
```

**Критерий приёмки D:** `in_venv` в выводе — `True`; скрипт печатает приветствие.

### Типовые проблемы (разбор по ходу блока D)

| Симптом | Действие |
|---------|----------|
| Не то ядро в ноутбуке | Клик по имени ядра вверху → `./.venv/.../python.exe` |
| `pip` ставит не в venv | Проверить `(.venv)`; `python -m pip install ...` |
| `Activate.ps1` не выполняется | `Set-ExecutionPolicy` или cmd + `activate.bat` |
| `python` не найден | `py -3 --version`; переустановка с PATH |
| После Restart Kernel пустой вывод | **Run All** |

---

## Завершение занятия

### Итоговый чеклист слушателя

| № | Действие | Готово |
|---|----------|--------|
| 1 | Python и VS Code, расширения Python + Jupyter | ☐ |
| 2 | Папка курса открыта в VS Code | ☐ |
| 3 | `.venv` создано и активируется | ☐ |
| 4 | Интерпретатор VS Code = `.venv\Scripts\python.exe` | ☐ |
| 5 | IPython установлен, есть `practice-ipython-log.txt` | ☐ |
| 6 | Jupyter-пакеты установлены | ☐ |
| 7 | `lab01-environment.ipynb` с выводом всех ячеек | ☐ |
| 8 | `practice-env-check.txt` с версиями и путями | ☐ |
| 9 | `hello.py` запускается из терминала | ☐ |

### Чеклист преподавателя

- Обойти 2–3 рабочих места: путь в `sys.executable` — из `.venv`.
- Попросить одного слушателя показать **Select Interpreter** и выбор ядра в ноутбуке.
- Убедиться, что артефакты лежат в **своей** папке/репозитории слушателя, а не скопированы.

---

## Справочник команд (кратко)

Создание и активация venv:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Установка инструментов модуля:

```powershell
python -m pip install --upgrade pip
pip install ipython notebook jupyterlab ipykernel
```

Проверки:

```powershell
python --version
ipython --version
jupyter --version
```

Ноутбук: создать `module-1/lab01-environment.ipynb` в VS Code, ядро из `.venv`.

---

## Домашняя доработка

1. Добавить в `module-1/` файл `.gitignore` со строками `.venv/` и `__pycache__/`.
2. Установить расширение **Python Environment Manager** (по желанию) и сравнить список окружений с ручной настройкой.
3. В IPython прочитать справку: `help("modules")` — одна строка в `practice-ipython-log.txt`.

После выполнения чеклиста рабочая среда готова для **Модуля 2. Основы Python**.