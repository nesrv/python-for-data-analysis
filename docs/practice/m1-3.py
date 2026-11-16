# --- list, dict, set ---
l = list()
l = []
l = ['123', [1,23], (1,2,3), {1,2,4}, {1:1, 2:2}]
l.append(('567',910))
l.extend(['567',910])
l.insert(1, ('new', 'item'))
l.remove('123')
l.pop()
print(l)
x = l.pop(0)
x = l.pop(0)
print(x)

# len, in, index, count, sort(), reverse()
from copy import deepcopy

l = ['123', [1, 23], (1, 2, 3), {1, 2, 4}, {1: 1, 2: 2}]

l1 = deepcopy(l)
l1[1] = 'new'

print(l)