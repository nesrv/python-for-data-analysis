# --- f-string  ---
name = 'Dima'
age = 30

s = f"Меня зовут {name.upper()}! мне {age ** 2}"

s = "Меня зовут {1}! мне {0}".format(name, age)

s = fr"Вино \"Ягодка малинка\"{age}"

print(s)

x = 54635343.14432423423
x = f'{x:.3f}'
print(x)

print(int(123) + "abc")

# --- tuple  ---
x = 'Дмитрий', ('Д', 'м')

print(x * 2 + ('Д', 'м'))

print(('Д', 'м') in x)

a, *b, c = 'Дмитрий'

print(b)