from pandas_datareader import data, wb
wb.search('gdp.*capita.*const').iloc[:,:2]
dat = wb.download(indicator='NY.GDP.PCAP.KD', country=['US', 'CA', 'MX'],start=2005, end=2017)
dat['NY.GDP.PCAP.KD'].groupby(level=0).mean()
wb.search('cell.*%').iloc[:,:2]
ind = ['NY.GDP.PCAP.KD', 'IT.MOB.COV.ZS']
wb.download(indicator=ind, country='all', start=2011, end=2011).dropna()
print(dat.tail())


import pandas_datareader.data as web
import datetime
df = web.DataReader('UN_DEN', 'oecd', end=datetime.datetime(2012, 1, 1))
df.columns

import pandas_datareader.data as web
df = web.DataReader("tran_sf_railac", 'eurostat')
df

import pandas_datareader.tsp as tsp
tspreader = tsp.TSPReader(start='2015-10-1', end='2015-12-31')
tspreader.read()



