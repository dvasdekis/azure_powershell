﻿### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                            # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
Set-Location F:\Labfiles
$WorkFolder = "F:\Labfiles\Lab3\" ; $TempFolder = "F:\Labfiles\" 
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$SLSFileOriginal = $workFolder + "StorageLinkedServiceOriginal.json"
$SLSFile = $workFolder + "StorageLinkedService.json"
$SQLFileOriginal = $workFolder + "AzureSQLLinkedServiceOriginal.json"
$SQLFile = $workFolder + "AzureSQLLinkedService.json"
$IDSFileOriginal = $workFolder + "BlobTableOriginal.json"
$IDSFile = $workFolder + "BlobTable.json"
$ODSFileOriginal = $workFolder + "SQLTableOriginal.json"
$ODSFile = $workFolder + "SQLTable.json"
$ODSName = "SQLTable"
$ADPFile = $workFolder + "ADP.json"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                              # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$DataFactoryName = $NamePrefix + "df"
$StorageAccountName = $NamePrefix + "sa"
$ContainerName = "adf"
$Location = "EASTUS"
$SQLServerName = $NamePrefix + "sql1"
$SQLServerLogin = "sqllogin1"                              # Login created for SQL Server Administration
$SQLServerLogin3 = "sqllogin3"                             # Login created for Database Administration
$Password = "Password123"
$SQLDatabase = "db1"
$SQLDatabaseTable = "Emp"  
$SQLDatabaseConnectionString = "jdbc:sqlserver://$SQLServerName.database.windows.net;user=$SQLServerLogin3@$SQLServerName;password=$Password;database=$SQLDatabase"
$LoginScript1 = Get-Content ($WorkFolder + "CreateSSLogin1.txt")
$LoginScript3 = Get-Content ($WorkFolder + "CreateSSLogin3.txt")
$TableScript = Get-Content ($WorkFolder + "SQLTable.txt")

### Log start time of script
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Create Data Factory" > $TempFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $TempFolder$LogFilePrefix$LogFileSuffix

### Login to Azure
# Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Azure Resource Group & Data Factory
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.DataFactory
New-AzureRmDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName –Location $Location



### Create Storage Account

New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value


### Create Azure SQL Server, Database & Table
$PWSQL = ConvertTo-SecureString -String $Password -AsPlainText -Force
$SQLCredential = New-Object System.Management.Automation.PSCredential($SQLServerLogin,$PWSQL)
New-AzureRMSQLServer -ResourceGroupName $ResourceGroupName -Location $Location -Servername $SQLServerName -SQLAdministratorCredentials $SQLCredential -ServerVersion "12.0"
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIP1" -StartIpAddress $ExternalIP -EndIPAddress $ExternalIP        
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -AllowAllAzureIPs
New-AzureRmSQLDatabase -ResourceGroupName $ResourceGroupName -Servername $SQLServerName -DatabaseName $SQLDatabase
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=master;User ID=$SQLServerLogin@$SQLServerName;Password=$Password;Trusted_Connection=False;Encrypt=True;"
$SAConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection.Open()
$CreateLogin = New-Object System.Data.SqlClient.SqlCommand($LoginScript1,$SAConnection)
$CreateLogin.ExecuteNonQuery()
$SAConnection.Close()
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=$SQLDatabase;User ID=$SQLServerLogin@$SQLServerName;Password=$Password;Trusted_Connection=False;Encrypt=True;"
$SAConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection.Open()
$CreateTable = New-Object System.Data.SqlClient.SqlCommand($LoginScript3,$SAConnection)
$CreateTable.ExecuteNonQuery()
$SAConnection.Close()
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=$SQLDatabase;User ID=$SQLServerLogin@$SQLServerName;Password=$Password;Trusted_Connection=False;Encrypt=True;"
$SAConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection.Open()
$CreateTable = New-Object System.Data.SqlClient.SqlCommand($TableScript,$SAConnection)
$CreateTable.ExecuteNonQuery()
$SAConnection.Close()


### Update Configuration Files
# Storage Linked Service File
Copy-Item $SLSFileOriginal $SLSFile -Force
(Get-Content $SLSFile) -Replace '<accountname>', $StorageAccountName | Set-Content $SLSFile

(Get-Content $SLSFile) -Replace '<accountkey>', $StorageAccountKey | Set-Content $SLSFile

# Input Dataset File

Copy-Item $IDSFileOriginal $IDSFile -Force
(Get-Content $IDSFile) -Replace '<folderpath>', "$ContainerName/input/" | Set-Content $IDSFile

# Output Dataset File

Copy-Item $ODSFileOriginal $ODSFile -Force
(Get-Content $ODSFile) -Replace '<OutputDatasetName>', $ODSName | Set-Content $ODSFile

# Azure SQL Linked Service File

Copy-Item $SQLFileOriginal $SQLFile -Force
(Get-Content $SQLFile) -Replace '<server>', $SQLServerName | Set-Content $SQLFile

(Get-Content $SQLFile) -Replace '<databasename>', $SQLDatabase | Set-Content $SQLFile

(Get-Content $SQLFile) -Replace '<user>', $SQLServerLogin3 | Set-Content $SQLFile

(Get-Content $SQLFile) -Replace '<password>', $Password | Set-Content $SQLFile



### Copy Configuration Files to Storage Blob

$Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

New-AzureStorageContainer -Name $ContainerName -Context $Context
Get-Childitem $WorkFolder -File -Recurse | Set-AzureStorageBlobContent -Container $ContainerName -Context $Context -Force



### Create Azure Storage & Azure SQL Linked Services

New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SLSFile -Force 

New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SQLFile -Force



### Create DataSets

New-AzureRmDataFactoryDataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $IDSFile -Force

New-AzureRmDataFactoryDataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $ODSFile -Force



### Create Pipeline

New-AzureRmDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $ADPFile -Force   

Start-Sleep 180

Suspend-AzureRMDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DatafactoryName $DataFActoryName -Name "ADFPipeline"


### Delete Resources and log end time of script
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$LogFilePrefix$LogFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$LogFilePrefix$LogFileSuffix 
Rename-Item -Path $TempFolder$LogFilePrefix$LogFileSuffix -NewName $et$LogFileSuffix
# Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force
