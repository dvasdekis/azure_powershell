# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
# dir(datetime.datetime) ; help(datetime.datetime)
import datetime
datestr = datetime.datetime.today().strftime("%Y-%m-%d_%H:%M:%S") 
datecalc = datetime.datetime.now() + datetime.timedelta(days=30) 

now = datetime.datetime.today()
numdays = 30
datelist = []
x = 0
while x < numdays:
   datelist.append(now - datetime.timedelta(days = x))
   x = x + 1

print(datelist)




