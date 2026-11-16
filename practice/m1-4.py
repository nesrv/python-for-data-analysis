# --- dict  ---
# ключ неизм тд
d = dict()
d = {}

d = {
    "name": 'Dima',
    "age": "30",
    "children": ('Andrew', 'Ann'),
    ("depart", "arm"): ["IT", "cluster-2"]
}

print (d.keys())
print (d.values())
print (*d.items(), sep='\n')

d = dict.fromkeys(['key1', 'key2'], 0)
print(d)

keys = ['key1', 'key2']
values = [1, 2]

d = dict(zip(keys, values))
print(d)

print(d['key1'])

print(d.get("key3"), 'нет')

d['key4'] = 4
d['key4'] = 40
d.update({'key1': 10, 'key2': 20})

x = d.popitem()
print('!', x)