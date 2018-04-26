# This script will create an "Orders Table" dataset with a million rows and export it to a CSV file
# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure

import os, random, datetime, numpy as np, pandas as pd
datestr = datetime.datetime.today().strftime("%Y%m%d")
workfolder = 'c:\\labfiles'
os.chdir(workfolder)
os.getcwd()

def new_orders():
 import os, random, decimal, string, csv, datetime, numpy as np, pandas as pd
 orderid = np.array(range(1,1000001))
 customerid = np.array([''.join(random.choice(string.ascii_uppercase) for _ in range(2)) + ''.join(random.choice(string.digits) for _ in range(2)) for _ in range(1000000)])
 employeeid = np.array([random.randint(110,990) for _ in range(1000000)])
 quantity = np.array([random.randint(1,100) for _ in range(1000000)])
 price = np.array([round(random.uniform(20, 100),2) for _ in range(1000000)])
 freight = np.array([round(random.uniform(10, 30),2) for _ in range(1000000)])
 now = datetime.datetime.now()
 orderdate = np.array([now - datetime.timedelta(days=(random.randint(360,420))) for _ in range(1000000)])
 shippeddate = np.array([now - datetime.timedelta(days=(random.randint(330,360))) for _ in range(1000000)])
 orderdata = zip(orderid,customerid,employeeid,quantity,price,freight,orderdate,shippeddate)
 orderdata1 = list(zip(orderid,customerid,employeeid,quantity,price,freight,orderdate,shippeddate))
 df = pd.DataFrame(orderdata1)
 df.to_csv('ordertable.csv',index=False,header=["OrderID","CustomerID","EmployeeID","Quantity","Price","Freight","OrderDate","ShippedDate"])


new_orders()



rowcount=1000
orderid = pd.read_csv('ordertable.csv',sep=',',nrows=rowcount).OrderID
orderdate = pd.read_csv('ordertable.csv',sep=',',nrows=rowcount).OrderDate  
price = pd.read_csv('ordertable.csv',sep=',',nrows=rowcount).Price
quantity = pd.read_csv('ordertable.csv',sep=',',nrows=rowcount).Quantity
total_l = []
count = 0
while count < rowcount:
 total_l.append(price[count] * quantity[count])
 count = count + 1


orders = pd.DataFrame(list(zip(orderid,orderdate,price,quantity,total_l)))
columns = ['OrderID','OrderDate','Price','Quantity','Total']
orders.columns = columns
orders.to_csv('orders.csv')


now = datetime.datetime.today()
numdays = 60
datelist = []
x = 0
while x < numdays:
   datelist.append(now - datetime.timedelta(days = x))
   x = x + 1

len(datelist)


import matplotlib.pyplot as plt
years = [2008,2009,2010,2011,2012,2013,2014,2015,2016,2017]
sales = [15000,18000,17000,17500,22000,32000,39000,89000,121000,289000]
plt.bar(years,sales)
plt.show()


# Configure Modules and Variables
import os, pandas as pd, pandas_datareader as dr, datetime,matplotlib.pyplot as plt
fig = plt.figure()
now = datetime.datetime.now()
begindate = now - datetime.timedelta(days=730)
workfolder = 'c:\\labfiles'
os.chdir(workfolder)
os.getcwd()
stock1 = 'DUK' 
stock2 = 'NGGL' 
stock3 = 'NEE' 
datestr = datetime.datetime.today().strftime("%Y%m%d%H%M")

# Download stock data for the last year
stockprice1 = dr.DataReader(stock1,"yahoo",begindate,now)   
stockprice2 = dr.DataReader(stock2,"yahoo",begindate,now)  
stockprice3 = dr.DataReader(stock3,"yahoo",begindate,now)    
 
# Export data to CSV files
file1 = datestr+'_'+stock1
file2 = datestr+'_'+stock2
file3 = datestr+'_'+stock3
stockprice1.to_csv(file1+'.csv',encoding='utf-8')
stockprice2.to_csv(file2+'.csv',encoding='utf-8')
stockprice3.to_csv(file3+'.csv',encoding='utf-8')

# Create lists to be used by Matplotlib
x1 = pd.read_csv(file1+'.csv',sep=',').Date  
x1 = [datetime.datetime.strptime(dates,'%Y-%m-%d').date() for dates in x1]
x2 = pd.read_csv(file2+'.csv',sep=',').Date 
x2 = [datetime.datetime.strptime(dates,'%Y-%m-%d').date() for dates in x2]
x3 = pd.read_csv(file3+'.csv',sep=',').Date
x3 = [datetime.datetime.strptime(dates,'%Y-%m-%d').date() for dates in x3]
y1 = pd.read_csv(file1+'.csv',sep=',').Close
y2 = pd.read_csv(file2+'.csv',sep=',').Close
y3 = pd.read_csv(file3+'.csv',sep=',').Close

# Create Chart
plt.title('Stock Prices of Largest Utility Companies')
plt.xlabel('Dates')
plt.ylabel('Stock Price')
plt.plot(x1,y1,label=stock1)
plt.plot(x2,y2,label=stock2)
plt.plot(x3,y3,label=stock3)
plt.grid()
plt.legend()

# Save and Display Chart
fig.savefig(datestr+'_'+stock1+'_'+stock2+'_'+stock3+'.pdf')
plt.show()

