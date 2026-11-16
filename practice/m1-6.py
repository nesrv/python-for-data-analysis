# --- csv  ---
import csv

users = [
    {"name": "Егор Тимофеев", "age": 90},
    {"name": "Марина Абрамова", "age": 12},
    {"name": "Никита Круглов", "age": 19}
]

# with open("users.csv", 'w', newline="") as f:
#     columns = "name", "age"
#     writer = csv.DictWriter(f, fieldnames=columns)
#     writer.writeheader()
#     writer.writerows(users)

with open("users.csv", encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(row["name"])

# --- json (бывш. m1-12) ---
import json

user = '[{"name": "Егор Тимофеев", "age": 90}, {"name": "Марина Абрамова", "age": 12}, {"name": "Никита Круглов", "age": 19}]'
us_l = json.loads(user)

users = [
    {"name": "Егор Тимофеев", "age": 90, "married": True},
    {"name": "Марина Абрамова", "age": 12.5, "children": ("Петя", "Вася")},
    {"name": "Никита Круглов", "age": 19}
]

with open("data.json", "w") as f:
    json.dump(users, f, ensure_ascii=False, indent=4)

with open("data.json",) as f:
    users = json.load(f)
    print(users)

# --- pickle  ---
import pickle

user = '{"name": "Егор Тимофеев", "age": 90}'

# with open("data.dat", "wb") as f:
#     pickle.dump(user, f)

with open("data.dat", "rb") as f:
    user = pickle.load(f)
    print(user)