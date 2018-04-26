### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                                             # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
Set-Location F:\Labfiles
$WorkFolder = "F:\Labfiles\Lab3\" ; $TempFolder = "F:\Labfiles\" 
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                              # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"
$DataFactoryName = $NamePrefix + "df"
$DataLakeName = $NamePrefix + "dl"
$AppName = $NamePrefix + "app"
$AppURI = "http://" + $AppName
$ContainerName = "adf"
$Location = "EASTUS"
$DataLocation = "NORTHEUROPE"
$BLOBLinkedServiceOriginal = $workFolder + "BLOBLinkedServiceOriginal.json"
$BLOBLinkedService = $workFolder + "BLOBLinkedService.json"
$BlobInputOriginal = $workFolder + "BlobInputOriginal.json"
$BlobInput = $workFolder + "BlobInput.json"
$SQLLinkedServiceOriginal = $workFolder + "SQLLinkedServiceOriginal.json"
$SQLLinkedService = $workFolder + "SQLLinkedService.json"
$SQLOutput = $workFolder + "SQLOutput.json"
$SQLOutput2 = $workFolder + "SQLOutput2.json"
$ADLPipeline1 = $workFolder + "ADLPipeline1.json"
$ADLPipelineT = $workFolder + "ADLPipelineT.json"
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
$ProcedureScript = Get-Content ($WorkFolder + "SQLProcedure.txt")

### Log start time of script
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Configure Azure Transformations" > $TempFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $TempFolder$LogFilePrefix$LogFileSuffix

### Login to Azure
# Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Azure Resource Group, Data Factory
Register-AzureRMResourceProvider -ProviderNamespace Microsoft.DataLakeAnalytics            # Only needs to be run once
Register-AzureRMResourceProvider -ProviderNamespace Microsoft.DataLakeStore                # Only needs to be run once
$RG = New-AzureRMResourceGroup -Name $ResourceGroupName  -Location $Location
$DF = New-AzureRMDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName –Location $DataLocation



### Create Storage Account

New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value


### Create and configure Data Lake

$DL = New-AzureRMDataLakeStoreAccount -ResourceGroupName $ResourceGroupName -Name $DataLakeName -Location $DataLocation -DisableEncryption
New-AzureRMDataLakeStoreItem -AccountName $DataLakeName -Path "`/$ContainerName" -Folder


### Create Azure Service Principal 
$GUID = [system.guid]::newguid()
$Key = ConvertTo-SecureString -String $GUID.GUID -AsPlainText -Force
$App = New-AzureRMADApplication -DisplayName $AppName -HomePage $AppURI -IdentifierUris $AppURI -Password $Key
$SP = New-AzureRMADServicePrincipal -ApplicationID $App.ApplicationID 
Start-Sleep 60
New-AzureRMRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $App.ApplicationID.GUID


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
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=$SQLDatabase;User ID=$SQLServerLogin@$SQLServerName;Password=$Password;Trusted_Connection=False;Encrypt=True;"
$SAConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection.Open()
$CreateTable = New-Object System.Data.SqlClient.SqlCommand($ProcedureScript,$SAConnection)
$CreateTable.ExecuteNonQuery()
$SAConnection.Close()


### Update Configuration Files
# BLOB Linked Service
Copy-Item $BLOBLinkedServiceOriginal $BlobLinkedService -Force
(Get-Content $BLOBLinkedService) -Replace '<accountname>', $StorageAccountName | Set-Content $BLOBLinkedService
(Get-Content $BLOBLinkedService) -Replace '<accountkey>', $StorageAccountKey | Set-Content $BLOBLinkedService

# SQL Linked Service
Copy-Item $SQLLinkedServiceOriginal $SQLLinkedService -Force
(Get-Content $SQLLinkedService) -Replace '<server>', $SQLServerName | Set-Content $SQLLinkedService
(Get-Content $SQLLinkedService) -Replace '<databasename>', $SQLDatabase | Set-Content $SQLLinkedService
(Get-Content $SQLLinkedService) -Replace '<user>', $SQLServerLogin3 | Set-Content $SQLLinkedService
(Get-Content $SQLLinkedService) -Replace '<password>', $Password | Set-Content $SQLLinkedService

# Blob Input

Copy-Item $BlobInputOriginal $BlobInput -Force
(Get-Content $BlobInput) -Replace '<folderpath>', "$ContainerName/input/" | Set-Content $BlobInput



### Copy Configuration Files to Azure Data Lake

Import-AzureRMDataLakeStoreItem -AccountName $DataLakeName -Path $WorkFolder -Destination "`/$ContainerName" -Recurse -Force



### Copy Configuration Files to Storage Blob

$Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

New-AzureStorageContainer -Name $ContainerName -Context $Context
Get-ChildItem $WorkFolder -File -Recurse | Set-AzureStorageBlobContent -Container $ContainerName -Context $Context -Force



### Create Azure Storage & Azure SQL Linked Services

New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $BLOBLinkedService -Force

New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SQLLinkedService -Force



### Create DataSets

New-AzureRmDataFactoryDataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $BlobInput -Force

New-AzureRmDataFactoryDataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SQLOutput -Force

New-AzureRmDataFactoryDataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SQLOutput2 -Force



### Create Pipeline

New-AzureRmDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $ADLPipeline1 -Force

Start-Sleep 180

Suspend-AzureRMDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DatafactoryName $DataFActoryName -Name "ADLPipeline1"

New-AzureRmDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $ADLPipelineT -Force

Start-Sleep 180

Resume-AzureRMDataFactoryPipeline -ResourceGroupName $ResourceGroupName -DatafactoryName $DataFActoryName -Name "ADLPipelineT"
Get-UsageAggregates -ReportedStartTime "09/01/2017" -ReportedEndTime (Get-Date -Format "MM/dd/yyyy")




### Delete Resources and log end time of script
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $TempFolder$logFilePrefix$logFileSuffix -NewName $et$logFileSuffix
# Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force ; Get-AzureRMADApplication | Where {$_.DisplayName -eq $AppName} | Remove-AzureRMADApplication -Force
 
