# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure

variable1 = 1
if variable1 == 1: 
   print("variable1 is equal to 1")
else:
   print("variable1 is not equal to 1")

variable1 = 3
if variable1 == 1:
   print("variable1 is equal to 1")
elif variable1 == 2:
   print("variable1 is equal to 2")
elif variable1 == 3:
   print("variable1 is equal to 3")
else:
   print("variable1 is not equal to 1, 2 or 3")

list1 = [1,2,3,4,5,6,7]
for num in list1:
   print(num)

variable1 = 0
while variable1 < 10: 
   print(variable1)
   variable1 = variable1 + 1 

variable1 = 0
while variable1 <= 100: 
   variable1 = variable1 + 1
   if variable1 == 98: print("variable1 is equal to 98.  End here.") ; break
   print("variable1 is equal to",variable1)

variable1 = 0
while variable1 <= 100: 
   variable1 = variable1 + 1 
   if variable1 == 98: continue
   print("variable1 is equal to",variable1)




