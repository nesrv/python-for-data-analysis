# 2.9. Классы, магические методы и основы ООП

**Объём занятия:** 2 академических часа (~120 минут) активной практики в Visual Studio Code.

**Цель:** описать свой тип через класс, научить объект магическим методам и переиспользовать поведение через метод класса, наследование и миксин.

**Опора:** ноутбук в VS Code, ядро — `./.venv/Scripts/python.exe`. Рабочая папка — корень курса.

**Итоговый артефакт:** `module-2-9/lab29-classes.ipynb` со всеми ячейками и сохранённым выводом.

Занятие объединяет классы и магические методы с основами ООП: метод класса, `__slots__`, dataclass, наследование, полиморфизм и миксин.

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

## Геттер и сеттер

Геттер читает поле, сеттер записывает его и может проверить значение до записи. Снаружи это либо явный вызов функции, либо обращение к атрибуту, за которым прячется декоратор `property`.

**Ячейка — через функции:**

```python
class Account:
    def __init__(self, balance):
        self._balance = balance

    def get_balance(self):
        return self._balance

    def set_balance(self, value):
        if value < 0:
            raise ValueError("баланс не может быть отрицательным")
        self._balance = value

acc = Account(100)
print(acc.get_balance())
acc.set_balance(250)
print(acc.get_balance())
```

`get_balance` и `set_balance` — обычные методы. Чтение и запись видны в вызове: скобки и аргумент. Поле `_balance` с подчёркивания — договорённость «не трогать напрямую».

**Ячейка — через декоратор:**

```python
class Account:
    def __init__(self, balance):
        self._balance = balance

    @property
    def balance(self):
        return self._balance

    @balance.setter
    def balance(self, value):
        if value < 0:
            raise ValueError("баланс не может быть отрицательным")
        self._balance = value

acc = Account(100)
print(acc.balance)
acc.balance = 250
print(acc.balance)
```

`@property` делает метод геттером: `acc.balance` вызывает `balance(self)` без скобок. `@balance.setter` вешает сеттер на то же имя: присваивание `acc.balance = 250` вызывает второй метод. Проверка та же, что в `set_balance`, но снаружи это выглядит как поле.

Если оставить только `@property` и не писать `@balance.setter`, чтение работает, а присваивание даёт `AttributeError`.

**Критерий:** и функция, и свойство не принимают отрицательный баланс; после `set_balance(250)` и после `acc.balance = 250` чтение возвращает `250`.

---

## Принципы ООП

Четыре принципа описывают, как устроен класс. Дальше по занятию каждый из них разбирается на своём примере.

**Инкапсуляция.** Данные и правила их изменения спрятаны внутри объекта. Снаружи работают методы или свойство, а не сырое поле.

```python
class Account:
    def __init__(self, balance):
        self._balance = balance

    @property
    def balance(self):
        return self._balance

    @balance.setter
    def balance(self, value):
        if value < 0:
            raise ValueError("баланс не может быть отрицательным")
        self._balance = value
```

**Наследование.** Подкласс получает поведение базового класса и добавляет своё. `Point3D` ниже умеет `move`, хотя метод написан в `Point`.

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def move(self, dx, dy):
        self.x += dx
        self.y += dy

class Point3D(Point):
    def __init__(self, x, y, z):
        super().__init__(x, y)
        self.z = z

p = Point3D(1, 2, 3)
p.move(1, 1)
print(p.x, p.y, p.z)
```

**Абстракция.** Базовый класс задаёт операцию, но не её реализацию. Конкретный класс обязан сказать, что эта операция делает.

```python
class Marker:
    def place(self):
        raise NotImplementedError

class Point(Marker):
    def __init__(self, x, y):
        self.x, self.y = x, y

    def place(self):
        return f"точка ({self.x}, {self.y})"
```

`Marker` не знает координат. Он только обещает метод `place`.

**Полиморфизм.** Один и тот же вызов работает с объектами разных классов. Цикл не спрашивает тип: у каждого объекта свой `place`.

```python
class Circle(Marker):
    def __init__(self, x, y, radius):
        self.x, self.y, self.radius = x, y, radius

    def place(self):
        return f"круг r={self.radius}"

for item in (Point(1, 2), Circle(0, 0, 5)):
    print(item.place())
```

**Критерий:** отрицательный баланс через свойство отклоняется; `Point3D` сдвигается методом базового класса; цикл печатает и точку, и круг одним вызовом `place`.

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

## 2.9.9. Метод класса и статический метод

Метод экземпляра работает с одной точкой. Метод класса получает сам класс аргументом `cls` и обычно создаёт экземпляр. Статический метод не получает ни точку, ни класс: это функция, которая логически живёт рядом с классом.

**Ячейка:**

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    @classmethod
    def origin(cls):
        return cls(0, 0)

    @staticmethod
    def same_place(left, right):
        return left.x == right.x and left.y == right.y

start = Point.origin()
other = Point(0, 0)
print(start.x, start.y, Point.same_place(start, other))
```

**Практика 2.9.9.** Добавьте метод класса `from_pair(cls, pair)`, который принимает кортеж `(x, y)` и возвращает точку. Проверьте на `(4, 5)`. Добавьте `copy`, который возвращает новый `Point` с теми же координатами, сдвиньте копию и убедитесь, что исходная точка не изменилась.

**Критерий 2.9.9:** `origin` даёт `(0, 0)`, `same_place` для двух таких точек истинен, `from_pair((4, 5))` даёт эти координаты. Сдвиг копии не меняет исходную точку.

---

## 2.9.10. __slots__

Обычный экземпляр хранит атрибуты в словаре `__dict__`. В `__slots__` перечисляют допустимые имена: лишнее поле создать нельзя, словарь на каждый экземпляр не заводится.

**Ячейка:**

```python
class SlotPoint:
    __slots__ = ("x", "y")

    def __init__(self, x, y):
        self.x = x
        self.y = y

p = SlotPoint(1, 2)
print(p.x, p.y, hasattr(p, "__dict__"))
```

Попытка `p.label = "A"` заканчивается `AttributeError`.

**Практика 2.9.10.** Поймайте эту ошибку через `try` / `except AttributeError` и напечатайте `"поле не предусмотрено"`.

**Критерий 2.9.10:** `__dict__` отсутствует. Ячейка с `except` печатает «поле не предусмотрено».

---

## 2.9.11. Dataclass

Для класса, который в основном хранит поля, декоратор `dataclass` сам пишет `__init__`, `__repr__` и `__eq__`. Параметр `slots=True` включает ограничение имён из раздела 2.9.10.

**Ячейка:**

```python
from dataclasses import dataclass

@dataclass(slots=True)
class Point:
    x: float
    y: float

    def move(self, dx, dy):
        self.x += dx
        self.y += dy

a = Point(2, 3)
b = Point(2, 3)
a.move(1, 0)
print(a, a == b)
```

**Практика 2.9.11.** Добавьте поле `label: str = ""`. Создайте `Point(1, 1)` без подписи и `Point(1, 1, "старт")`. Напечатайте оба объекта.

**Критерий 2.9.11:** после сдвига печать показывает `Point(3, 3)`, сравнение с копией даёт `False`. Точка без подписи имеет пустую строку в `label`.

---

## 2.9.12. Наследование

Подкласс забирает методы базового класса и добавляет своё. `super()` вызывает версию базового класса. В этой ячейке нужен рукописный `Point` с `__init__`, `__repr__` и `move`, не dataclass: у него другой способ объявления полей. Если имя `Point` уже занято предыдущей ячейкой, выполните этот класс заново.

**Ячейка:**

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __repr__(self):
        return f"Point({self.x}, {self.y})"

    def move(self, dx, dy):
        self.x += dx
        self.y += dy

class Point3D(Point):
    def __init__(self, x, y, z):
        super().__init__(x, y)
        self.z = z

    def __repr__(self):
        return f"Point3D({self.x}, {self.y}, {self.z})"

    def lift(self, dz):
        self.z += dz

p = Point3D(1, 2, 3)
p.move(1, 1)
p.lift(4)
print(p, isinstance(p, Point))
```

**Практика 2.9.12.** Добавьте в `Point3D` метод `__add__`, который складывает и `z`. Проверьте `Point3D(1, 1, 1) + Point3D(2, 3, 4)`.

**Критерий 2.9.12:** после `move` и `lift` объект печатается как `Point3D(2, 3, 7)`. Сумма равна `Point3D(3, 4, 5)`. `isinstance` относительно `Point` истинен.

---

## 2.9.13. Полиморфизм

Один и тот же вызов метода у объектов разных классов. Цикл не проверяет тип: у каждого объекта есть свой `place`.

**Ячейка:**

```python
class Marker:
    def place(self):
        raise NotImplementedError

class Point(Marker):
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def place(self):
        return f"точка ({self.x}, {self.y})"

class Circle(Marker):
    def __init__(self, x, y, radius):
        self.x = x
        self.y = y
        self.radius = radius

    def place(self):
        return f"круг ({self.x}, {self.y}) r={self.radius}"

def describe(items):
    for item in items:
        print(item.place())

describe([Point(1, 2), Circle(0, 0, 5)])
```

**Практика 2.9.13.** Добавьте класс `Label` с методом `place`, который возвращает текст подписи. Передайте его в тот же `describe` третьим элементом.

**Критерий 2.9.13:** в выводе есть строка про точку, строка про круг и строка подписи. В `describe` нет проверки `isinstance`.

---

## 2.9.14. Миксин

Миксин — небольшой класс с одним дополнительным поведением. Его не создают сам по себе: подмешивают в класс слева в списке базовых классов.

**Ячейка:**

```python
class LabelMixin:
    def tagged(self):
        return f"[{self.label}] {self.place()}"

class NamedPoint(LabelMixin, Point):
    def __init__(self, x, y, label):
        super().__init__(x, y)
        self.label = label

item = NamedPoint(2, 3, "старт")
print(item.place())
print(item.tagged())
```

`NamedPoint` берёт `place` у `Point` и `tagged` у `LabelMixin`. Порядок `LabelMixin, Point` важен: Python ищет метод слева направо. Классы `Point` и `Circle` должны быть из раздела 2.9.13.

**Практика 2.9.14.** Сделайте `NamedCircle(LabelMixin, Circle)` и напечатайте `tagged()` для круга с подписью `"зона"`.

**Критерий 2.9.14:** у именованной точки `tagged()` содержит `[старт]` и текст `place`. У именованного круга в строке есть `[зона]` и радиус.

---

## 2.9.15. Самопроверка

В конце ноутбука ответьте в markdown:

1. Чем класс отличается от экземпляра и зачем методу `self`.
2. Почему `__add__` лучше возвращает новый объект, а не число.
3. Чем метод экземпляра отличается от метода класса.
4. Что запрещает `__slots__` и что в примере даёт наследование, а что даёт миксин.

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
| 9 | `origin`, `from_pair` и независимая `copy` работают | ☐ |
| 10 | У `SlotPoint` нет `__dict__`, лишнее поле даёт `AttributeError` | ☐ |
| 11 | Dataclass сравнивает точки по полям и принимает `label` по умолчанию | ☐ |
| 12 | `Point3D` пользуется `move` базового класса и складывает третью координату | ☐ |
| 13 | `describe` печатает точку, круг и подпись одним циклом | ☐ |
| 14 | `NamedPoint` и `NamedCircle` получают `tagged` из миксина | ☐ |
| 15 | Четыре ответа самопроверки | ☐ |

### Типовые ошибки

| Симптом | Что проверить |
|---------|----------------|
| `TypeError: set_coords() takes 2 positional arguments but 3 were given` | В методе забыт `self` |
| `Point(1, 2) == Point(1, 2)` ложно | Нет `__eq__` |
| `TypeError: unhashable type` | Есть `__eq__`, но нет `__hash__` |
| После `account = account + 300` нет поля `name` | `__add__` вернул число, а не новый счёт |
| `for` по `FRange` не заканчивается | В `__next__` нет `StopIteration`, когда значение достигло `stop` |
| `origin` возвращает базовый `Point` у подкласса | Внутри метода класса создание идёт через `cls(...)` |
| `p.label = ...` у slots молча создаёт поле | В классе нет `__slots__` или поле `label` в него уже внесено |
| Миксин не находит `place` | `place` есть у второго базового класса, а `tagged` вызывает `self.place()` |

После занятия слушатель описывает свой тип, подключает проверки, равенство, сложение и перебор, ограничивает набор полей и переиспользует поведение через базовый класс и миксин.
