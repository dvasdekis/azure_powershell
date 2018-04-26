
# Step 1 - Configure Objects & Variables
# The below section is almost generic boilerplate
Set-StrictMode -Version 2.0
$SubscriptionName = "Azure Pass"
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition #magic line to get the dir of the script as a variable
$workFolder = "$scriptPath\" ; $TempFolder = "C:\temp\" 
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$Location = "EASTUS"
$namePrefix = ("DV" + (Get-Date -Format "HHmmss")).ToLower()  
$ResourceGroupName = $namePrefix + "rg" # arbritrary
$ContainerName = "adf" # arbritrary
$azcopyPath = "C:\AzCopy" # Path to installed version of AzCopy
$DataFactoryName = $namePrefix + "df" # arbritrary
$ODSName = "SQLTable" # arbritrary
$StorageAccountName = $namePrefix + "sa" # arbritrary
$DataLakeName = $namePrefix + "dl"

## SQL Server-specific variables
$SQLServerName = $namePrefix + "sql1"
$SQLDatabase = "db1"
$SQLServerLogin = "sqllogin1"                              # Login created for SQL Server Administration
$SQLServerLogin3 = "sqllogin3"                             # Login created for Database Administration
$Password = "Password123"
$SQLDatabaseTable = "Emp"

## Here lies all the config file template paths
$SLSFileOriginal = $workFolder + "StorageLinkedServiceOriginal.json"
$SLSFile = $TempFolder + "StorageLinkedService.json"
$SQLFileOriginal = $workFolder + "AzureSQLLinkedServiceOriginal.json"
$SQLFile = $TempFolder + "AzureSQLLinkedService.json"
$IDSFileOriginal = $workFolder + "BlobTableOriginal.json"
$IDSFile = $TempFolder + "BlobTable.json"
$ODSFileOriginal = $workFolder + "SQLTableOriginal.json"
$ODSFile = $TempFolder + "SQLTable.json"
$ADPFile = $workFolder + "ADP.json"

## Log start time of script
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Create Data Factory" > $TempFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $TempFolder$LogFilePrefix$LogFileSuffix

Write-Host "Delete and recreate the temp folder" # Write-Host is the Powershell version of Echo
Remove-Item $TempFolder -Recurse
New-Item -Path $TempFolder -ItemType directory
# End Variable Configs
##############################################################################################################



# Step 2 - Initialise the infrastructure
Write-Host "Login to Azure"
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

Write-Host "Register the Azure services in case you dont have them"
### Create Azure Resource Group, Data Factory
Register-AzureRMResourceProvider -ProviderNamespace Microsoft.DataLakeAnalytics            # Only needs to be run once
Register-AzureRMResourceProvider -ProviderNamespace Microsoft.DataLakeStore                # Only needs to be run once

Write-Host "Create a Resource group to hold everything"
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location

Write-Host "Create a Storage Account"
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value

Write-Host "Create a Data Lake"
$DL = New-AzureRmDataLakeStoreAccount -ResourceGroupName $ResourceGroupName -Name $DataLakeName -Location $Location -DisableEncryption
New-AzureRmDataLakeStoreItem -AccountName $DataLakeName -Path "`/$ContainerName" -Folder

Write-Host "Create an Azure Service Principal"
$GUID = [system.guid]::newguid()
$Key = ConvertTo-SecureString -String $GUID.GUID -AsPlainText -Force
$App = New-AzureRMADApplication -DisplayName $AppName -HomePage $AppURI -IdentifierUris $AppURI -Password $Key
$SP = New-AzureRMADServicePrincipal -ApplicationID $App.ApplicationID 
Start-Sleep 60
New-AzureRMRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $App.ApplicationID.GUID

Write-Host "Create a SQL Server instance"
$SQLCredential = New-Object System.Management.Automation.PSCredential($SQLServerLogin,$PWSQL)
New-AzureRMSQLServer -ResourceGroupName $ResourceGroupName -Location $Location -Servername $SQLServerName -SQLAdministratorCredentials $SQLCredential -ServerVersion "12.0"
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIP1" -StartIpAddress $ExternalIP -EndIPAddress $ExternalIP        
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -AllowAllAzureIPs
New-AzureRmSQLDatabase -ResourceGroupName $ResourceGroupName -Servername $SQLServerName -DatabaseName $SQLDatabase

Write-Host "Setting up the SQL Server"
### Define SQL Server Parameters
#### As JDBC
$SQLDatabaseConnectionString = "jdbc:sqlserver://$SQLServerName.database.windows.net;user=$SQLServerLogin3@$SQLServerName;password=$Password;database=$SQLDatabase"
$PWSQL = ConvertTo-SecureString -String $Password -AsPlainText -Force
#### As Native Powershell
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=master;User ID=$SQLServerLogin@$SQLServerName;Password=$Password;Trusted_Connection=False;Encrypt=True;"
$SAConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)

### Now, let's log on and create our user
Write-Host "Creating login $SQLServerLogin3 on SQL server"
$SAConnection.Open()
$LoginScript1 = "CREATE LOGIN $SQLServerLogin3 WITH PASSWORD = '$Password'"
$CreateLogin = New-Object System.Data.SqlClient.SqlCommand($LoginScript1,$SAConnection)
$CreateLogin.ExecuteNonQuery()
$SAConnection.Close()

Write-Host "We now login as $SQLServerLogin3 and give login $SQLServerLogin3 a username and roles on the SQL server"
$LoginScript2 = "CREATE USER sqllogin3 FOR LOGIN sqllogin3 WITH DEFAULT_SCHEMA = dbo"
$LoginScript3 = "EXEC sp_addrolemember db_owner, sqllogin3"
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=$SQLDatabase;User ID=$SQLServerLogin@$SQLServerName;Password=$Password;Trusted_Connection=False;Encrypt=True;"
$SAConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection.Open()
$LoginScript2onserver = New-Object System.Data.SqlClient.SqlCommand($LoginScript2,$SAConnection)
$LoginScript2onserver.ExecuteNonQuery()
$LoginScript3onserver = New-Object System.Data.SqlClient.SqlCommand($LoginScript3,$SAConnection)
$LoginScript3onserver.ExecuteNonQuery()
$SAConnection.Close()
Write-Host "Succesfully created roles for $SQLServerLogin3"


################################################################################################################



# Step 3 - Pass the details of the infrastructure you'll need to Data Factory
### Set all the config files that deal with storage
Write-Host "Update the config/linked storage files"
Write-Host "Note - a linked storage file is like a connection string for Data Factory"
#### Storage Linked Service File
Copy-Item $SLSFileOriginal $SLSFile -Force
(Get-Content $SLSFile) -Replace '<accountname>', $StorageAccountName | Set-Content $SLSFile
(Get-Content $SLSFile) -Replace '<accountkey>', $StorageAccountKey | Set-Content $SLSFile
#### Data Lake Linked Service
Copy-Item $ADLLinkedServiceOriginal $ADLLinkedService -Force
(Get-Content $ADLLinkedService) -Replace '<accountname>', $DataLakeName | Set-Content $ADLLinkedService
(Get-Content $ADLLinkedService) -Replace '<resourcegroupname>', $ResourceGroupName | Set-Content $ADLLinkedService
(Get-Content $ADLLinkedService) -Replace '<serviceprincipalid>', $App.ApplicationID.GUID | Set-Content $ADLLinkedService
(Get-Content $ADLLinkedService) -Replace '<serviceprincipalkey>', $Key.GUID | Set-Content $ADLLinkedService
(Get-Content $ADLLinkedService) -Replace '<subscriptionid>', $Subscription.Subscription.SubscriptionID | Set-Content $ADLLinkedService
(Get-Content $ADLLinkedService) -Replace '<tenantid>', $Subscription.Tenant.TenantID | Set-Content $ADLLinkedService
#### Input Dataset File
Copy-Item $IDSFileOriginal $IDSFile -Force
(Get-Content $IDSFile) -Replace '<folderpath>', "$ContainerName/input/" | Set-Content $IDSFile
#### Output Dataset File
Copy-Item $ODSFileOriginal $ODSFile -Force
(Get-Content $ODSFile) -Replace '<OutputDatasetName>', $ODSName | Set-Content $ODSFile
#### Azure SQL Linked Service File
Copy-Item $SQLFileOriginal $SQLFile -Force
(Get-Content $SQLFile) -Replace '<server>', $SQLServerName | Set-Content $SQLFile
(Get-Content $SQLFile) -Replace '<databasename>', $SQLDatabase | Set-Content $SQLFile
(Get-Content $SQLFile) -Replace '<user>', $SQLServerLogin3 | Set-Content $SQLFile
(Get-Content $SQLFile) -Replace '<password>', $Password | Set-Content $SQLFile



####################################################################################################################################



# Step 4 - Load any reference data, and start the Pipeline
Write-Host "Copy Input File to Storage Blob"
$azcopycmd = "cmd.exe /C '$azcopyPath\AzCopy.exe' /S /Y /Source:'$WorkFolder' /Dest:'https://$StorageAccountName.blob.core.windows.net/adf' /DestKey:$StorageAccountKey"
Invoke-Expression -Command:$azcopycmd


Write-Host "Create table in database"
$CTScript1 = @"
CREATE TABLE dbo.emp
(
ID INT IDENTITY(1,1) PRIMARY KEY,
LastName NVARCHAR(50),
FirstName NVARCHAR(50),
HireDate Date,
HireTime Time
)
"@
$SAConnection2 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection2.Open()
$CTScript1onserver = New-Object System.Data.SqlClient.SqlCommand($CTScript1,$SAConnection2)
$CTScript1onserver.ExecuteNonQuery()
$SAConnection2.Close()
Write-Host "We now have a table inside our Database"


# Load the data into blob, and then into our table

Write-Host "Create Data Factory"
New-AzureRmDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName –Location $Location

Write-Host "Create Azure Storage & HDInsight Linked Services"
# $SLSFile contains the Blob Storage instance details and credentials (but not, for example, the foldername)
New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SLSFile
# $SQLFile contains the details of the SQL Server instance (eg. Server address/DB) and credentials (but not the table name/DDL)
New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SQLFile

Write-Host "Create DataSets in Data Factory"
# Passes the Data Factory group details to the two lines below
$DF = Get-AzureRmDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName 
# $IDSFile - Inbound DataSource File. Because we're loading from Blob to SQL Server, this contains the Blob file specs
New-AzureRmDataFactoryDataset $DF -File $IDSFile
# $ODSFile - Outbound DataSource File. Contains the SQL Server table details, including DDL.
New-AzureRmDataFactoryDataset $DF -File $ODSFile

Write-Host "Create Data Pipelines in Data Factory"
# The $ADPFile holds the ETL instructions for the Data Factory job.
New-AzureRmDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $ADPFile -Force   
Start-Sleep 180   # sleeps this script for 3 minutes. Gives the job 3 minutes to run, otherwise it's long-lived.
Suspend-AzureRMDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DatafactoryName $DataFActoryName -Name "ADFPipeline"

# Close and kill everything
Write-Host "Delete everything in the Resource group we just created"
Remove-AzureRmResourceGroup -Name $ResourceGroupName
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$LogFilePrefix$LogFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$LogFilePrefix$LogFileSuffix 
Rename-Item -Path $TempFolder$LogFilePrefix$LogFileSuffix -NewName $et$LogFileSuffix

Write-Host "Script complete!"