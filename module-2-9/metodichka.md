# 2.9. Классы и магические методы

**Объём занятия:** 2 академических часа (~120 минут) активной практики в Visual Studio Code.

**Цель:** описать свой тип через класс, создать экземпляр и научить его вести себя в `bool`, сравнениях, арифметике, индексации и цикле `for`.

**Опора:** ноутбук в VS Code, ядро — `./.venv/Scripts/python.exe`. Рабочая папка — корень курса.

**Итоговый артефакт:** `module-2-9/lab29-classes.ipynb` со всеми ячейками и сохранённым выводом.

Материал собран по конспектам `python-2/m4` и `python-2/m6`.

---

## Подготовка

Создайте ноутбук `module-2-9/lab29-classes.ipynb` и выберите ядро `.venv`. Первая ячейка — markdown: ФИО, дата, заголовок «2.9 Классы и магические методы».

Класс — чертёж объекта: какие данные он хранит и какие действия умеет. Экземпляр — конкретный объект по этому чертежу. Имя класса пишут с большой буквы.

---

## 2.9.1. Класс и экземпляр

**Ячейка:**

```python
class Point:
    pass

origin = Point()
print(type(Point))
print(type(origin))
print(isinstance(origin, Point))
```

`type(Point)` — `type`: класс сам является объектом. `type(origin)` — `Point`. `isinstance` проверяет, сделан ли объект по этому чертежу.

**Практика 2.9.1.** Создайте второй экземпляр `other = Point()` и проверьте `origin is other`.

**Критерий 2.9.1:** `isinstance` истинен, `origin is other` ложен: это два разных объекта одного класса.

---

## 2.9.2. Атрибуты и self

Данные экземпляра — существительные, методы — глаголы. При вызове через экземпляр Python сам передаёт этот экземпляр первым аргументом. Его имя по соглашению — `self`.

**Ячейка:**

```python
class Point:
    def set_coords(self, x, y):
        self.x = x
        self.y = y

    def get_coords(self):
        return self.x, self.y

a = Point()
a.set_coords(3, 4)
print(a.get_coords())
```

`Point.set_coords(a, 3, 4)` — тот же вызов, первый аргумент указан явно. Если убрать `self` из определения, вызов через экземпляр даст `TypeError`: интерпретатор всё равно подставит объект.

**Критерий 2.9.2:** `get_coords` возвращает `(3, 4)`.

---

## 2.9.3. Инициализатор __init__

`__init__` вызывается сразу после создания экземпляра. В нём задают начальные поля, чтобы не вызывать отдельный `set_coords`.

**Ячейка:**

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __repr__(self):
        return f"Point({self.x}, {self.y})"

a = Point(1, 2)
b = Point(3, 4)
print(a, b)
```

`__repr__` задаёт текст, который ноутбук показывает для объекта. Без него печать выглядит как `<Point object at 0x...>`.

**Практика 2.9.3.** Добавьте метод `move(self, dx, dy)`, который меняет координаты на месте и возвращает `self`. Вызовите `Point(1, 2).move(2, 3)`.

**Критерий 2.9.3:** после `move` объект печатается как `Point(3, 5)`.

---

## 2.9.4. __bool__ и __len__

`bool` для обычного экземпляра всегда истинен. Свой смысл задают `__bool__` или, если его нет, `__len__`. Ненулевая длина считается истиной.

**Ячейка:**

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __len__(self):
        return self.x * self.x + self.y * self.y

print(bool(Point(3, 4)))
print(bool(Point(0, 0)))
```

`__bool__` имеет приоритет над `__len__`. Точка ложна, когда обе координаты нулевые:

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __bool__(self):
        return not (self.x == 0 and self.y == 0)

print(bool(Point(0, 1)))
print(bool(Point(0, 0)))
```

**Критерий 2.9.4:** `Point(3, 4)` истинен, `Point(0, 0)` ложен и через длину, и через `__bool__`.

---

## 2.9.5. __eq__ и __hash__

Два экземпляра с одинаковыми координатами без `__eq__` не равны: `==` сравнивает, тот ли это объект. Хеш можно считать только у неизменяемого значения. Если определён `__eq__` и не определён `__hash__`, объект нельзя положить в множество и использовать как ключ словаря.

**Ячейка:**

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __eq__(self, other):
        return isinstance(other, Point) and self.x == other.x and self.y == other.y

    def __hash__(self):
        return hash((self.x, self.y))

print(Point(1, 2) == Point(1, 2))
print(len({Point(1, 2), Point(1, 2), Point(0, 0)}))
```

Равные объекты обязаны иметь равный хеш. Обратное неверно: одинаковый хеш ещё не значит равенство.

**Критерий 2.9.5:** сравнение двух точек `(1, 2)` истинно. В множестве остаётся **2** элемента.

---

## 2.9.6. __add__

Оператор `+` вызывает `__add__`. Метод должен вернуть новый объект того же класса, а не голое число: иначе имя перестаёт указывать на счёт.

**Ячейка:**

```python
class BankAccount:
    def __init__(self, name, balance):
        self.name = name
        self.balance = balance

    def __add__(self, other):
        return BankAccount(self.name, self.balance + other)

    def __repr__(self):
        return f"BankAccount({self.name!r}, {self.balance})"

ivan = BankAccount("Иван", 100)
ivan = ivan + 300
print(ivan)
```

**Практика 2.9.6.** Добавьте `__sub__` для снятия суммы. `BankAccount("Пётр", 200) - 50` должен оставить баланс 150. Отрицательный результат не запрещайте.

**Критерий 2.9.6:** после пополнения печать показывает `BankAccount('Иван', 400)`. После снятия баланс Петра равен **150**.

---

## 2.9.7. __getitem__ и __setitem__

Квадратные скобки вызывают `__getitem__` при чтении и `__setitem__` при записи.

**Ячейка:**

```python
class Student:
    def __init__(self, name, marks):
        self.name = name
        self.marks = list(marks)

    def __getitem__(self, index):
        return self.marks[index]

    def __setitem__(self, index, value):
        self.marks[index] = value

sergey = Student("Сергей", [5, 5, 3, 2, 5])
print(sergey[2])
sergey[2] = 4
print(sergey[2], sergey.marks)
```

**Критерий 2.9.7:** до записи третий элемент — `3`, после записи список равен `[5, 5, 4, 2, 5]`.

---

## 2.9.8. __iter__ и __next__

Цикл `for` вызывает `iter`, затем `next`, пока не возникнет `StopIteration`. Так делают прогрессию дробных чисел: у `range` шаг только целый.

**Ячейка:**

```python
class FRange:
    def __init__(self, start, stop, step=0.5):
        self.start = start
        self.stop = stop
        self.step = step

    def __iter__(self):
        self.current = self.start
        return self

    def __next__(self):
        if self.current >= self.stop:
            raise StopIteration
        value = self.current
        self.current += self.step
        return value

print(list(FRange(0, 2, 0.5)))
```

**Практика 2.9.8.** Посчитайте сумму `FRange(1, 3, 1)` циклом `for`. Правая граница, как у `range`, не входит.

**Критерий 2.9.8:** список равен `[0, 0.5, 1.0, 1.5]`. Сумма целого диапазона равна **3**.

---

## 2.9.9. Самопроверка

В конце ноутбука ответьте в markdown:

1. Чем класс отличается от экземпляра.
2. Зачем методу первый параметр `self`.
3. Почему `__add__` лучше возвращает новый `BankAccount`, а не число.

### Чеклист

| № | Действие | Готово |
|---|----------|--------|
| 1 | Два `Point()` — разные объекты одного класса | ☐ |
| 2 | `set_coords` записывает координаты через `self` | ☐ |
| 3 | `__init__` и `move` дают `Point(3, 5)` | ☐ |
| 4 | Нулевая точка ложна в `bool` | ☐ |
| 5 | Равные точки совпадают, в множестве их одна | ☐ |
| 6 | Счёт пополняется через `+` и уменьшается через `-` | ☐ |
| 7 | Оценка читается и меняется квадратными скобками | ☐ |
| 8 | `FRange` даёт четыре дробных шага и сумму 3 | ☐ |
| 9 | Три ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| `TypeError: set_coords() takes 2 positional arguments but 3 were given` | В методе забыт `self` |
| `Point(1, 2) == Point(1, 2)` ложно | Нет `__eq__` |
| `TypeError: unhashable type` | Есть `__eq__`, но нет `__hash__` |
| После `account = account + 300` нет поля `name` | `__add__` вернул число, а не новый счёт |
| `for` по `FRange` не заканчивается | В `__next__` нет `StopIteration`, когда значение достигло `stop` |

После занятия слушатель описывает свой тип, создаёт объекты с начальными полями и подключает для них проверки, равенство, сложение, индекс и перебор.
