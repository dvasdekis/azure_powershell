# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
# dir(pandas) ; help(pandas)
import pandas

# Create Lists and Dataframes
firstname_l = ['John','George','Sandy','Violet','Irene']
lastname_l = ['Brown','Washington','Collins','Harris','Smith']
age_l = [23,43,19,33,29]
phone_l = ['111-222-3333','404-555-1234','519-888-0000','203-432-1212','303-999-0987']
email_l = ['john@yahoo.com','george@outlook.com','sandy@gmail.com','violet@netscape.com','irene@lycos.com']
id_l = [104,105,103,101,102]
firstname_df = pandas.DataFrame(firstname_l)
lastname_df = pandas.DataFrame(lastname_l)
age_df = pandas.DataFrame(age_l)
phone_df = pandas.DataFrame(phone_l)
email_df = pandas.DataFrame(email_l)
id_df = pandas.DataFrame(id_l)

# Combine Lists and Dataframes
records_df1 = pandas.DataFrame(list(zip(firstname_l,lastname_l,age_l,phone_l,email_l)))
records_df2 = pandas.concat([firstname_df,lastname_df,age_df,phone_df,email_df],axis=1)
columns = ['firstname','lastname','age','phone','email']
records_df1.columns = columns
records_df2.columns = columns

# Merge Dataframes
records_df3 = pandas.concat([id_df,firstname_df,lastname_df],axis=1)
records_df4 = pandas.concat([id_df,age_df,phone_df,email_df],axis=1)
columns3 = ['id','firstname','lastname']
columns4 = ['id','age','phone','email']
records_df3.columns = columns3
records_df4.columns = columns4
records_df5 = pandas.merge(records_df3,records_df4, on='id')

# Sort Data
records_df5.sort_values(by=['lastname'])
records_df5.sort_values(by='id',ascending=False)
records_df6 = records_df5.set_index('id')
records_df6.index.name

# Change Working Directory
import os
os.chdir('c:\\labfiles')
os.getcwd()

# Export/Import Data To/From Datasets
records_df6.to_csv('records6.csv') ; records_df6.to_json('records6.json')
records6_csv = pandas.read_csv('records6.csv')


