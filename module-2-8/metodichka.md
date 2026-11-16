# 2.8. Замыкания и декораторы

**Объём занятия:** 2 академических часа (~120 минут) активной практики в Visual Studio Code.

**Цель:** отличать локальную переменную от внешней, удерживать значение во вложенной функции и добавлять поведение функции декоратором.

**Опора:** разделы 2.6 и 2.7, ноутбук в VS Code, ядро — `./.venv/Scripts/python.exe`.

**Итоговый артефакт:** `module-2-8/lab28-closures.ipynb` со всеми ячейками и сохранённым выводом.

Материал опирается на конспекты из `python-2/m2`.

---

## Подготовка

Создайте ноутбук `module-2-8/lab28-closures.ipynb` и выберите ядро `.venv`. Первая ячейка — markdown: ФИО, дата, заголовок «2.8 Замыкания и декораторы».

---

## 2.8.1. Локальная и глобальная переменная

Присваивание внутри функции создаёт локальное имя. Оно не меняет глобальное имя с тем же написанием. `global` явно говорит: менять нужно имя модуля.

**Ячейка:**

```python
name = "Илья"

def say_hi():
    name = "Иван"
    print("Привет,", name)

def say_bye():
    print("Пока,", name)

say_hi()
say_bye()
print("снаружи:", name)
```

**Ячейка — global:**

```python
def say_hi_global():
    global name
    name = "Иван"
    print("Привет,", name)

say_hi_global()
say_bye()
```

**Критерий 2.8.1:** до `global` прощание печатает «Илья». После `say_hi_global` прощание печатает «Иван».

---

## 2.8.2. nonlocal

`nonlocal` берёт имя из ближайшей внешней функции, не из модуля. Для глобального имени оно не подходит: там нужен `global`.

**Ячейка:**

```python
x = 0

def outer():
    x = 1

    def inner():
        nonlocal x
        x = 2
        print("inner:", x)

    inner()
    print("outer:", x)

outer()
print("global:", x)
```

Без `nonlocal` присваивание `x = 2` создало бы локальное имя, и `outer` по-прежнему напечатал бы `1`.

**Критерий 2.8.2:** печать идёт в порядке `inner: 2`, `outer: 2`, `global: 0`.

---

## 2.8.3. Замыкание

Вложенная функция помнит переменные внешней, если внешняя вернула её, а не вызвала сразу. Это замыкание: внутреннее окружение живо, пока на функцию есть ссылка.

**Ячейка:**

```python
def say_name(name):
    def say_goodbye():
        return "Don't say me goodbye, " + name + "!"
    return say_goodbye

sergey = say_name("Sergey")
python = say_name("Python")
print(sergey())
print(python())
```

Два вызова `say_name` дают два независимых окружения.

**Ячейка — счётчик:**

```python
def counter(start=0):
    def step():
        nonlocal start
        start += 1
        return start
    return step

c1 = counter(10)
c2 = counter()
print(c1(), c2())
print(c1(), c2())
print(c1(), c2())
```

Без `nonlocal` строка `start += 1` пытается читать локальное имя до присваивания и падает с `UnboundLocalError`.

**Практика 2.8.3.** Сделайте `strip_string(chars=" ")`, которая возвращает функцию одной строки. `strip_string()` убирает пробелы. `strip_string(" !?.")` убирает ещё эти знаки. Проверьте обе на `" hello python!.. "`.

**Критерий 2.8.3:** счётчики печатают `11 1`, затем `12 2`, затем `13 3`. Первая обрезка даёт `hello python!..`, вторая — `hello python`.

---

## 2.8.4. Декоратор

Декоратор принимает функцию и возвращает новую, которая вызывает исходную и добавляет действия до или после неё.

**Ячейка:**

```python
def func_decorator(func):
    def wrapper(*args, **kwargs):
        print("перед вызовом")
        result = func(*args, **kwargs)
        print("после вызова")
        return result
    return wrapper

def some_func(title, tag):
    print(f"title = {title}, tag = {tag}")
    return f"<{tag}>{title}</{tag}>"

some_func = func_decorator(some_func)
print(some_func("Python", "h1"))
```

`*args` и `**kwargs` принимают любое число аргументов. `return result` нужен, иначе снаружи получится `None`.

Запись через `@` делает то же присваивание в момент объявления:

```python
@func_decorator
def title_of(text):
    return text.upper()

print(title_of("функции"))
```

**Критерий 2.8.4:** вокруг вызова печатаются две служебные строки, а результат равен `<h1>Python</h1>`. `title_of` возвращает `ФУНКЦИИ`.

---

## 2.8.5. Декоратор с проверкой и замер времени

Один и тот же декоратор можно повесить на разные функции. Условие доступа смотрит внешнее имя `user`.

**Ячейка:**

```python
user = "admin"

def access(func):
    def wrapper(*args, **kwargs):
        if user != "admin":
            return "access denied"
        return func(*args, **kwargs)
    return wrapper

@access
def read_db():
    return "reading data base"

print(read_db())
user = "guest"
print(read_db())
user = "admin"
```

**Ячейка — время:**

```python
import time

def test_time(fn):
    def wrapper(*args, **kwargs):
        started = time.perf_counter()
        result = fn(*args, **kwargs)
        elapsed = time.perf_counter() - started
        print(f"время работы: {elapsed:.6f} сек")
        return result
    return wrapper

@test_time
def fib(n):
    a, b = 1, 1
    for _ in range(2, n):
        a, b = b, a + b
    return b

print(fib(20))
```

Рекурсивный Фибоначчи для замера не используем: он повторяет одни и те же вызовы. Здесь цикл считает 20-е число, декоратор печатает длительность.

**Практика 2.8.5.** Напишите `show_menu`. Он вызывает функцию, получает список пунктов и печатает их с номерами, начиная с 1. Функция `get_menu` только режет строку по пробелам.

```python
def show_menu(func):
    def wrapper(text):
        items = func(text)
        for index, item in enumerate(items, start=1):
            print(f"{index}. {item}")
        return items
    return wrapper

@show_menu
def get_menu(text):
    return text.split()

print(get_menu("Файл Правка Вид"))
```

**Критерий 2.8.5:** для гостя `read_db` возвращает `access denied`. `fib(20)` равен **6765**. Меню печатает три строки: `1. Файл`, `2. Правка`, `3. Вид`.

---

## 2.8.6. lru_cache

`functools.lru_cache` запоминает результат по аргументам. Повторный вызов с теми же аргументами не выполняет тело снова. Для рекурсии с повторами это убирает лишние ветки. Глубину в тысячи вызовов на занятии не используют.

**Ячейка:**

```python
from functools import lru_cache

@lru_cache(maxsize=None)
def fact(n):
    if n == 1:
        return 1
    return n * fact(n - 1)

print(fact(6))
print(fact.cache_info())
```

`cache_info()` показывает, сколько ответов взято из памяти (`hits`) и сколько посчитано заново (`misses`).

**Практика 2.8.6.** Вызовите `fact(6)` второй раз и сравните `hits` до и после.

**Критерий 2.8.6:** `fact(6)` равен **720**. После второго вызова `hits` больше, чем после первого.

---

## 2.8.7. Самопроверка

В конце ноутбука ответьте в markdown:

1. Чем `global` отличается от `nonlocal`.
2. Почему счётчик без `nonlocal` не может сделать `start += 1`.
3. Почему декоратор без `return result` превращает полезный результат в `None`.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | Локальное имя не затирает глобальное, `global` затирает | ☐ |
| 2 | `nonlocal` меняет `x` внешней функции и не трогает модуль | ☐ |
| 3 | Два замыкания `say_name` помнят разные имена | ☐ |
| 4 | Два счётчика идут независимо: 11/1, 12/2, 13/3 | ☐ |
| 5 | `@func_decorator` печатает текст до и после вызова и возвращает строку | ☐ |
| 6 | Меню пронумеровано, `fib(20)` равен 6765 | ☐ |
| 7 | Повторный `fact(6)` увеличивает `hits` | ☐ |
| 8 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| `UnboundLocalError` на `start += 1` | Во вложенной функции есть `nonlocal start` |
| `SyntaxError` на `nonlocal` | Имя объявлено не в функции, а в модуле: нужно `global` |
| Декоратор не принимает второй аргумент | У `wrapper` есть `*args, **kwargs`, и они переданы в исходную функцию |
| После декоратора результат `None` | `wrapper` возвращает значение исходной функции |
| `fact` считает заново каждый раз | Над функцией стоит `@lru_cache`, вызов идёт по тому же имени |

После занятия слушатель удерживает состояние во вложенной функции и добавляет к готовой функции проверку, печать или замер, не переписывая её тело.
