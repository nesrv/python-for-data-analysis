# while + continue + break + else

from time import sleep


def counter():
    c = 0
    while True:
        print('счетчик = ', c)
        c += 1
        yield


def printer():
    c = 0
    while True:
        if c % 3 == 0:
            print('печать ...')
        c += 1
        yield
        
c1 = counter()
p1 = printer()


while True:
    next(c1)
    sleep(0.5)
    next(p1)
    sleep(0.5)
