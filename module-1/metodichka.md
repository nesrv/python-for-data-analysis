# Модуль 1. Введение и настройка рабочей среды

**Цель:** подготовить удобную среду для курса: Python в изолированном окружении, **IPython**, **Jupyter** в редакторе **Visual Studio Code**.

---

## 1. Что установить заранее

1. **Python 3.10+** с [python.org](https://www.python.org/downloads/) (при установке отметьте **Add Python to PATH**).
2. **Visual Studio Code** с [code.visualstudio.com](https://code.visualstudio.com/).

Проверка в терминале VS Code (`Терминал` → `Создать терминал` или `` Ctrl+` ``):

```powershell
python --version
```

Должна отобразиться версия Python 3.x.

---

## 2. Расширения VS Code для Python и Jupyter

1. Откройте панель расширений: `Ctrl+Shift+X`.
2. Установите:
   - **Python** (Microsoft) — подсветка, отладка, выбор интерпретатора.
   - **Jupyter** (Microsoft) — открытие и запуск `.ipynb` прямо в VS Code.

После установки перезапустите VS Code, если редактор это предложит.

---

## 3. Рабочая папка и открытие проекта

1. Создайте папку для курса (например `IT-cloud`).
2. В VS Code: **Файл** → **Открыть папку** → выберите эту папку.

Так вы получите единый корень проекта: терминал по умолчанию откроется в нём, пути к файлам будут короткими.

---

## 4. Создание виртуального окружения Python

Виртуальное окружение изолирует библиотеки курса от системного Python.

### Через встроенный терминал VS Code

В корне проекта выполните (Windows PowerShell):

```powershell
python -m venv .venv
```

Появится папка `.venv` с копией интерпретатора и местом для пакетов.

### Активация окружения

**PowerShell:**

```powershell
.\.venv\Scripts\Activate.ps1
```

Если PowerShell запрещает скрипты, один раз для текущего пользователя можно разрешить выполнение:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Командная строка cmd:**

```cmd
.venv\Scripts\activate.bat
```

В начале строки терминала появится префикс `(.venv)` — значит, окружение активно.

### Привязка интерпретатора в VS Code

1. `Ctrl+Shift+P` → команда **Python: Select Interpreter**.
2. Выберите `./.venv/Scripts/python.exe` (или пункт с пометкой **Recommended**).

В статусной строке внизу будет отображаться выбранный Python — удобно проверять, что используется именно venv.

---

## 5. Установка IPython

С **активированным** `.venv` в терминале:

```powershell
python -m pip install --upgrade pip
pip install ipython
```

Проверка:

```powershell
ipython --version
```

Запуск интерактивной оболочки:

```powershell
ipython
```

Выход: `exit` или `Ctrl+D`.

**В VS Code:** после выбора интерпретатора `.venv` команда **Python: Start REPL** (`Ctrl+Shift+P`) открывает REPL с тем же Python; для полноценного IPython удобнее запускать `ipython` из терминала.

---

## 6. Установка и настройка Jupyter Notebooks

### Установка пакетов

В активированном окружении:

```powershell
pip install notebook jupyterlab ipykernel
```

`ipykernel` регистрирует ваше окружение как «ядро» для Jupyter.

### Регистрация ядра для текущего venv (по желанию)

Если нужно явное имя ядра в списке VS Code:

```powershell
python -m ipykernel install --user --name=it-cloud --display-name "Python (IT-cloud)"
```

Дальше в Jupyter в VS Code можно выбрать ядро **Python (IT-cloud)**.

### Работа с `.ipynb` в VS Code

1. Создайте файл, например `module-1/demo.ipynb` (**Файл** → **Новый файл** → сохраните с расширением `.ipynb`).
2. Откройте его — откроется встроенный редактор ноутбуков.
3. В правом верхнем углу выберите **ядро**: интерпретатор из `.venv` (или созданное выше ядро **Python (IT-cloud)**).
4. Добавьте ячейку кода (`+ Code`), наберите, например:

```python
import sys
print(sys.executable)
```

Нажмите **Run** у ячейки или `Shift+Enter`. В выводе должен быть путь к `python.exe` внутри `.venv`.

### Запуск классического Jupyter в браузере (альтернатива)

Из терминала с активным `.venv`:

```powershell
jupyter lab
```

или

```powershell
jupyter notebook
```

Браузер откроется сам; работа ведётся в веб-интерфейсе. В курсе достаточно **режима VS Code**, если не сказано иначе.

---

## 7. Краткий чеклист

| Шаг | Действие |
|-----|----------|
| 1 | Установлены Python и VS Code |
| 2 | Установлены расширения **Python** и **Jupyter** |
| 3 | Открыта папка проекта в VS Code |
| 4 | Создано окружение `python -m venv .venv` |
| 5 | Активировано окружение, выбран интерпретатор в VS Code |
| 6 | Выполнено `pip install ipython notebook jupyterlab ipykernel` |
| 7 | Создан тестовый `.ipynb`, ядро — из `.venv`, ячейка выполняется |

---

## 8. Типичные проблемы

- **В VS Code не то ядро в ноутбуке** — нажмите на название ядра вверху ноутбука и выберите `./.venv/.../python.exe`.
- **`Activate.ps1` не выполняется** — см. раздел про `Set-ExecutionPolicy` или используйте cmd.
- **`python` не найден** — переустановите Python с опцией PATH или укажите полный путь к `py -3`.

После успешной проверки чеклиста рабочая среда для дальнейших модулей готова.
