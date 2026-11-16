# --- txt: чтение  ---
# txt, csv, json, pickle
# w, a

# with open("txt.txt") as f:
#     f.write('\n123\n')
#     f.write('456')
#     print('\n789', file=f)

with open("txt.txt") as f:
    s1 = f.read()
    print(s1)

    f.seek(0)
    s2 = f.readlines()
    print(s2)

    f.seek(0)
    s3 = f.readline().strip()
    print(s3)

    s3 = f.readline().strip()
    print(s3)

# --- best_employees: > 4 часов (бывш. m1-9) ---
# Напишите программу, которая определяет пользователей,
# работавших в системе более 4 часов, и записывает их
# имена и фамилии в файл best_employees.txt.

from datetime import datetime, timedelta

with open("txt.txt") as f:
    for s in f:
        s = s.strip().split(', ')
        fio, t1, t2 = s
        t1 = datetime.strptime(t1, "%H:%M")
        t2 = datetime.strptime(t2, "%H:%M")
        if t1 > t2:
            t2 += timedelta(days=1)
            dt = t2 - t1
        dt = t2 - t1

        if dt.total_seconds() / 3600 > 4:
            print(fio, dt)

# --- txt: map, включения  ---
from math import prod

# with open("txt.txt") as f:
#    s = f.readline().split(', ')
#    s = { int(x): int(x) ** 2 for x in s}
#    print(s)

with open("txt.txt") as f:
    s = f.readlines()
    s = map(int, s)
    print(*s)