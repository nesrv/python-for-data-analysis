# 3.2. Подключение к СУБД на примере PostgreSQL

**Объём занятия:** 2 академических часа (~120 минут) активной практики в Visual Studio Code.

**Цель:** поднять локальный PostgreSQL 18 в Docker, проверить его из терминала и из DBeaver и прочитать таблицу из ноутбука Jupyter.

**Опора:** окружение `.venv` и ноутбуки из модуля 1. Ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка VS Code — корень курса.

Пароль ниже только для учебной базы на своём компьютере.

**Итоговые артефакты** (в папке `module-3-2/`):

| Файл | Назначение |
|------|------------|
| `docker-compose.yml` | Описание контейнера PostgreSQL 18 |
| `lab32-postgres.ipynb` | Подключение, создание таблицы, выборка в pandas |
| `data/scores_from_db.csv` | Выгрузка результата запроса |

---

## Кратко: как поднимается база

1. Установить **Docker Desktop** и убедиться, что демон Docker запущен.
2. В `module-3-2/docker-compose.yml` описать сервис `postgres:18`: порт `5432`, имя базы, пользователь и пароль.
3. Запустить контейнер командой `docker compose up -d` и проверить `SELECT version()`.
4. Подключиться тем же хостом и портом из **DBeaver**.
5. Из `.ipynb` открыть соединение через SQLAlchemy и `psycopg`, создать таблицу и прочитать её в `DataFrame`.

Дальше те же шаги расписаны так, чтобы их можно было выполнить на занятии.

---

## 3.2.1. Docker Desktop: установка и первые команды

Docker Desktop запускает контейнеры в Linux-окружении Windows (обычно через WSL 2).

1. Скачайте установщик с [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/).
2. Установите его и перезагрузите компьютер, если установщик этого попросит.
3. Запустите **Docker Desktop** и дождитесь состояния **Engine running**.
4. В терминале VS Code проверьте клиент:

```powershell
docker version
docker compose version
```

В выводе `docker version` должны быть и Client, и Server. Если Server недоступен, Docker Desktop ещё не запущен.

Полезные команды на занятии:

| Команда | Зачем |
|---------|--------|
| `docker ps` | контейнеры, которые сейчас работают |
| `docker images` | уже скачанные образы |
| `docker compose up -d` | создать и запустить сервисы из файла Compose |
| `docker compose ps` | состояние сервисов этого файла |
| `docker compose logs` | журнал контейнера |
| `docker compose down` | остановить и убрать контейнеры этого файла |

Образ сам по себе ещё не база. База появляется, когда контейнер запущен и в нём стартовал PostgreSQL.

**Критерий 3.2.1:** `docker version` показывает Server, `docker compose version` печатает версию Compose.

---

## 3.2.2. Файл docker-compose.yml

Compose описывает, какой образ взять, как назвать контейнер, какие порты открыть и какие переменные передать PostgreSQL при первом создании данных.

Создайте `module-3-2/docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:18
    container_name: pg18-course
    environment:
      POSTGRES_USER: student
      POSTGRES_PASSWORD: student
      POSTGRES_DB: course
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U student -d course"]
      interval: 5s
      timeout: 5s
      retries: 10

volumes:
  pgdata:
```

Что означает каждая часть:

| Поле | Смысл |
|------|--------|
| `services.postgres` | один сервис в этом файле |
| `image: postgres:18` | официальный образ PostgreSQL 18 |
| `container_name` | фиксированное имя контейнера, по нему удобно вызывать `docker exec` |
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | учётная запись и база, которые образ создаёт при первом запуске |
| `ports: "5432:5432"` | порт компьютера слева, порт внутри контейнера справа |
| `volumes.pgdata` | данные переживут перезапуск контейнера |
| `healthcheck` | Docker проверяет, что сервер уже принимает подключения |

Каталог данных внутри образа PostgreSQL 18 — `/var/lib/postgresql`. Не монтируйте туда случайную пустую папку проекта: сервер не найдёт свой кластер.

**Критерий 3.2.2:** файл лежит в `module-3-2`, в нём образ `postgres:18`, пользователь `student`, база `course`, порт `5432`.

---

## 3.2.3. Запуск и проверка контейнера

Команды выполняйте из каталога, где лежит файл:

```powershell
cd module-3-2
docker compose up -d
docker compose ps
```

В столбце статуса ожидается `running` или `healthy`. Первый запуск скачивает образ и занимает несколько минут.

Журнал, если статус другой:

```powershell
docker compose logs
```

Проверка версии SQL из контейнера:

```powershell
docker exec pg18-course psql -U student -d course -c "SELECT version();"
```

В тексте версии должна быть **PostgreSQL 18**.

Короткий учебный запрос:

```powershell
docker exec pg18-course psql -U student -d course -c "CREATE TABLE IF NOT EXISTS ping (id int); INSERT INTO ping VALUES (1); SELECT * FROM ping;"
```

Остановка после занятия, данные тома сохраняются:

```powershell
docker compose stop
```

Снова поднять:

```powershell
docker compose start
```

`docker compose down` удаляет контейнер, но именованный том `pgdata` оставляет. `docker compose down -v` удаляет и том: база создаётся заново, таблицы пропадают.

**Критерий 3.2.3:** `SELECT version()` показывает PostgreSQL 18, запрос к `ping` возвращает строку `1`.

---

## 3.2.4. DBeaver

DBeaver — настольный просмотрщик баз. Им проверяют, что сервер виден не только из Docker.

1. Установите **DBeaver Community** с [dbeaver.io/download](https://dbeaver.io/download/).
2. **База данных** → **Новое подключение** → **PostgreSQL**.
3. Если DBeaver предложит скачать драйвер PostgreSQL, согласитесь.
4. Заполните параметры:

| Поле | Значение |
|------|----------|
| Хост | `localhost` |
| Порт | `5432` |
| База данных | `course` |
| Пользователь | `student` |
| Пароль | `student` |

5. **Тест подключения**, затем **Готово**.
6. Откройте базу `course` → **Схемы** → `public` → **Таблицы**. Таблица `ping` из предыдущего шага должна быть в списке.
7. Вкладка **SQL** у соединения. Выполните:

```sql
SELECT id FROM ping;
```

Результат — одна строка со значением `1`.

Если тест не проходит, сначала посмотрите `docker compose ps`: контейнер должен быть запущен, порт `5432` не должен быть занят другим PostgreSQL на компьютере.

**Критерий 3.2.4:** тест подключения в DBeaver успешен, `SELECT id FROM ping` возвращает `1`.

---

## 3.2.5. Подключение из ноутбука

Установите драйвер и SQLAlchemy в `.venv`:

```powershell
cd ..
.\.venv\Scripts\Activate.ps1
python -m pip install "psycopg[binary]" sqlalchemy pandas
```

Создайте `module-3-2/lab32-postgres.ipynb`, ядро — `.venv`.

Первая ячейка — markdown: ФИО, дата, заголовок «3.2 Подключение к PostgreSQL».

**Ячейка — соединение:**

```python
import sqlalchemy as sa

engine = sa.create_engine(
    "postgresql+psycopg://student:student@localhost:5432/course"
)
with engine.connect() as conn:
    version = conn.execute(sa.text("SELECT version()")).scalar()
print(version)
```

Строка подключения собирается так: `postgresql+psycopg://пользователь:пароль@хост:порт/база`. Префикс `postgresql+psycopg` говорит SQLAlchemy использовать драйвер psycopg 3.

**Критерий 3.2.5:** ячейка печатает ту же PostgreSQL 18, что и `docker exec`.

---

## 3.2.6. Таблица и запросы из Jupyter

Создайте таблицу с баллами и прочитайте её.

**Ячейка:**

```python
import pandas as pd

with engine.begin() as conn:
    conn.execute(sa.text("DROP TABLE IF EXISTS scores"))
    conn.execute(sa.text("""
        CREATE TABLE scores (
            name text NOT NULL,
            group_code text NOT NULL,
            score integer
        )
    """))
    conn.execute(
        sa.text("""
            INSERT INTO scores (name, group_code, score)
            VALUES
                ('Анна', 'A', 18),
                ('Борис', 'A', 15),
                ('Вера', 'B', 20),
                ('Глеб', 'B', NULL)
        """)
    )

frame = pd.read_sql(sa.text("SELECT name, group_code, score FROM scores ORDER BY name"), engine)
print(frame)
print("пропусков в score:", int(frame["score"].isna().sum()))
```

`engine.begin()` фиксирует транзакцию: и `CREATE`, и `INSERT` попадут в базу. `NULL` в SQL — это пропуск, в pandas он становится `NaN`.

Обновите список таблиц в DBeaver. Таблица `scores` и четыре строки должны быть видны.

**Практика 3.2.6.** Выберите только заполненные баллы и посчитайте сумму:

```python
filled = pd.read_sql(
    sa.text("SELECT name, score FROM scores WHERE score IS NOT NULL ORDER BY score"),
    engine,
)
print(filled)
print("сумма", int(filled["score"].sum()))
```

**Критерий 3.2.6:** в выборке нет Глеба, сумма равна **53**. Те же четыре строки открываются в DBeaver.

---

## 3.2.7. Выгрузка результата

Сохраните выборку в CSV, чтобы её можно было открыть без базы.

```python
from pathlib import Path

out = Path("module-3-2/data/scores_from_db.csv")
out.parent.mkdir(parents=True, exist_ok=True)
filled.to_csv(out, index=False, encoding="utf-8")
print(out.read_text(encoding="utf-8"))
```

**Критерий 3.2.7:** в файле три строки данных, заголовок `name,score`, сумма баллов по файлу совпадает с запросом.

---

## 3.2.8. Самопроверка

В конце ноутбука ответьте в markdown:

1. Чем образ `postgres:18` отличается от запущенного контейнера `pg18-course`.
2. Зачем в Compose указаны и порт слева, и порт справа в `"5432:5432"`.
3. Почему пароль из Compose совпадает с паролем в строке подключения ноутбука и в DBeaver.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | Docker Desktop запущен, `docker version` показывает Server | ☐ |
| 2 | `module-3-2/docker-compose.yml` с образом `postgres:18` | ☐ |
| 3 | `docker compose ps` — контейнер `pg18-course` работает | ☐ |
| 4 | `SELECT version()` из `docker exec` показывает PostgreSQL 18 | ☐ |
| 5 | DBeaver подключается к `localhost:5432`, база `course` | ☐ |
| 6 | Ноутбук печатает версию через SQLAlchemy | ☐ |
| 7 | Таблица `scores` видна и в ноутбуке, и в DBeaver, сумма заполненных баллов 53 | ☐ |
| 8 | `data/scores_from_db.csv` записан | ☐ |
| 9 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| `docker: failed to connect` или пустой Server | Запустить Docker Desktop и дождаться Engine running |
| Порт 5432 занят | Остановить локальный PostgreSQL или в Compose поставить другой левый порт, например `"5433:5432"`, и тот же порт указать в DBeaver и в строке подключения |
| `password authentication failed` | Пользователь и пароль как в `POSTGRES_*`. Если том уже создавался с другими значениями, смените их в Compose и выполните `docker compose down -v`, затем `up -d` |
| Контейнер сразу завершается | `docker compose logs`: часто это неверный путь тома |
| `ModuleNotFoundError: psycopg` | `python -m pip install "psycopg[binary]" sqlalchemy pandas` в `.venv` и то же ядро в ноутбуке |
| Кириллица в DBeaver искажена | Кодировка клиента UTF-8; файл CSV сохранять с `encoding="utf-8"` |

После занятия слушатель поднимает учебный PostgreSQL одной командой Compose и подключается к нему из DBeaver и из ноутбука одними и теми же host, port, database, user и password.
