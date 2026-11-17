from timeit import timeit


def slow_sum(n: int) -> int:
    total = 0
    for i in range(n): # 01
        total += i
    return total


def fast_sum(n: int) -> int: # 1
    return n * (n - 1) // 2


# test  = timeit("slow_sum(100_000)", number=100)

# t_slow = timeit("slow_sum(1_100_000)", number=100, globals=globals())
print (timeit("n * (n - 1) // 2", number=500, setup="n = 1_100_000"))

t_fast = timeit("fast_sum(1_100_000)", number=100, globals=globals())
# t_slow2 = timeit("slow_sum(100_000)", setup="from __main__ import slow_sum", number=100)

# print(t_slow)
print(t_fast)



    
    


 