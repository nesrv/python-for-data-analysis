def slow_sum(n: int) -> int:
    total = 0
    for i in range(n): # 01
        total += i
    return total


def fast_sum(n: int) -> int: # 1
    return n * (n - 1) // 2


def main():
    '''
    дирижер
    '''  
    print(slow_sum(100_000_000))
    print(fast_sum(100_000_000_000)) 
    
    

if __name__ == "__main__":
    main()
    
 