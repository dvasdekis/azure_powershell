# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure

def pvalue1(val1):
   print(val1)

pvalue1("This is a test.")

def pvalue2(val1="This is a test"):
   print(val1)

pvalue2()

def hello1():
   h = "Hello Everyone!"
   return

def hello2():
   h = "Hello Everyone!"
   return h

h1 = hello1() ; print h1
h2 = hello2() ; print h2

def pstring1(string1):
   print(string1)
   return

def pstring2():
   global string1
   string1 = raw_input("Type a string to be printed: ")
   print(string1)
   return

def ptotal1():
   print("Enter two numbers to be added:")
   n1 = input("Enter the first number:  ")
   n2 = input("Enter the second number: ")
   n3 = n1+n2
   print n1,"+",n2,"=",n3
   return n3






