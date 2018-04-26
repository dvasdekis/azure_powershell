# pip install --user --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
# print(plt.style.available)
import pandas as pd
import datetime
import pandas_datareader as dr
import matplotlib.pyplot as plt
now = datetime.datetime.now()
begindate = now - datetime.timedelta(days=730)
stockprice = dr.DataReader("AEP","yahoo",begindate,now)
print(stockprice)
stockprice.to_csv('stockprice.csv',encoding='utf-8')
sp = pd.read_csv('stockprice.csv', sep=',')
plt.style.use('ggplot')
fig = plt.figure()
x = sp['Date']
x = [datetime.datetime.strptime(dates,'%Y-%m-%d').date() for dates in x]
y = sp['Close']
plt.xlabel('Dates')
plt.ylabel('Stock Price')
plt.title('Stock Prices For The Last Two Years')
plt.plot(x,y)
# plt.gcf().autofmt_xdate(%m)
fig.savefig('stockprice.pdf')
fig.savefig('stockprice.png')
plt.show()

