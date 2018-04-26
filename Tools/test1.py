# pip install --user --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
# print(plt.style.available)
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


import matplotlib.pyplot as plt
years = [2008,2009,2010,2011,2012,2013,2014,2015,2016,2017]
sales = [15000,18000,17000,17500,22000,32000,39000,89000,121000,289000]
plt.bar(years,sales)
plt.show()



import pandas as pd
import datetime
import pandas_datareader as dr
import matplotlib.pyplot as plt
now = datetime.datetime.now()
begindate = now - datetime.timedelta(days=365)
stockprice = dr.DataReader("MSFT","yahoo",begindate,now)
print(stockprice)
stockprice.to_csv('stockprice.csv',encoding='utf-8')
sp = pd.read_csv('stockprice.csv', sep=',')
x = sp['Date']
y = sp['Close']
plt.title('MSFT Stock Prices For The Last Year')
plt.xlabel('Dates')
plt.ylabel('Stock Price')
plt.legend()
plt.plot(x,y)
plt.grid()
plt.show()

