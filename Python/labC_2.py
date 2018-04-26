# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
import numpy as np
int1 = 5
int2 = 5+5
int3 = int1 + int2
print(int3)
str1 = "This is "
str2 = "a test."
str3 = str1 + str2
print(str3)
type(int3)
type(str3)
print(str(int3))
# Will generate an error.  Cannot convert non-numeric string to an integer.
print(int(str3))
tuple1 = (1,2,3,4,5)
list1 = [1,2,3,4,5]
list1.append(6)
print(list1)
array1 = np.array(list1)
list1=list1*2
array1=array1*2
print(list1)
print(array1)

