# This script will create an "Orders Table" dataset with a million rows and export it to a CSV file
# pip install --user --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure

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


total = pandas.DataFrame(total_l)
orders = pd.DataFrame(list(zip(orderid,orderdate,price,quantity,total)))
columns = ['OrderID','OrderDate','Price','Quantity','Total']
orders.columns = columns



now = datetime.datetime.today()
numdays = 60
datelist = []
x = 0
while x < numdays:
   datelist.append(now - datetime.timedelta(days = x))
   x = x + 1


len(datelist)



