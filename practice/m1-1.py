'''
изменяемые и неизменяемые(хешируемые) тд
типизация строгая динамическая
int, float, bool, str, byte
tuple, frozenset, frozendict
'''

# --- типы, Decimal, операторы ---
from math import sqrt
from decimal import *

x = Decimal('0.1')
y = x + x + x

# print (0.3 == float(y))
# print(True + 1 + False + 3)

print ([] and ('Александр' or '123'))


class int:
    def __add__(self, value):
        return super().__mul__(value)


x = int(2)
x = x + 5  # *

for x in range(1, 10, 0.5):
    print(x)

# --- методы строк  ---


x = '.,!  Дмитрий, из мск  ..... '
x = 'abc123@mail.ru'

print('@' in x and x.endswith('.ru') and x.split('.')[-1].isalpha() and x.split('@')[0].isalnum())

# --- строки из многострочного текста (бывш. m1-3) ---
s = '''

изменяемые и неизменяемые(хешируемые) тд
типизация строгая динамическая
int, float, bool, str, byte
tuple, frozenset, frozendict


'''.strip().splitlines()[-1]

print(s.upper())