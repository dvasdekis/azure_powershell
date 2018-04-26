# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
# dir(matplotlib) ; help(matplotlib.pyplot) ; print(plt.style.available) ; type(plt.show)
import os, pandas as pd, pandas_datareader as dr, datetime,matplotlib.pyplot as plt
fig = plt.figure()
now = datetime.datetime.now()
begindate = now - datetime.timedelta(days=365)
workfolder = 'c:\\labfiles'
os.chdir(workfolder)
os.getcwd()
stock1 = 'MSFT' 
stock2 = 'ORCL' 
stock3 = 'SAP' 
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
plt.title('Stock Prices of Largest Software Companies')
plt.xlabel('Dates')
plt.ylabel('Stock Price')
# plt.gcf().autofmt_xdate(%m)
# plt.bar(x1,y1,label=stock1)
plt.plot(x1,y1,label=stock1)
plt.plot(x2,y2,label=stock2)
plt.plot(x3,y3,label=stock3)
plt.grid()
plt.legend()

# Save and Display Chart
fig.savefig(datestr+'_'+stock1+'_'+stock2+'_'+stock3+'.pdf')
fig.savefig(datestr+'_'+stock1+'_'+stock2+'_'+stock3+'.png')
plt.show()


