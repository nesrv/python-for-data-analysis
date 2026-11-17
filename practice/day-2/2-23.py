try:
    
    print(1/1)
    print(1) 
    print (1+1)
    f = open("myfile.txt")
except (ArithmeticError, FileNotFoundError) as err:                                 
    print(err)   
            
except NameError as err:                                 
    print(err)

except TypeError:   
    print('TypeError')  

else:
    print("искючений не было")
finally:
    print("Блок finally выполняется всегда")