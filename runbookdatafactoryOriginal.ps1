### Create Data Factory using Certificate-based credentials on a Service Principal
$SubscriptionID = "<subscriptionid>"
$TenantID = "<tenantid>"
$ApplicationID = "<applicationid>"
$CertificateThumbprint = "<certificatethumbprint>"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                             # Replace "in" with your initials
$Location = "EASTUS"
# $StorageAccountKey = "<storageaccountkey>"
$WorkFolder = "C:\Labfiles\Lab3\" ; $TempFolder = "C:\Labfiles\" 
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$AlertEmail = "realemail@address.com"                                                    # "specify a real email address you want to use for alerts in this lab
$SLSFileOriginal = $workFolder + "StorageLinkedServiceOriginal.json"
$SLSFile = $workFolder + "StorageLinkedService.json"
$SQLFileOriginal = $workFolder + "AzureSQLLinkedServiceOriginal.json"
$SQLFile = $workFolder + "AzureSQLLinkedService.json"
$IDSFileOriginal = $workFolder + "BlobTableOriginal.json"
$IDSFile = $workFolder + "BlobTable.json"
$ODSFileOriginal = $workFolder + "SQLTableOriginal.json"
$ODSFile = $workFolder + "SQLTable.json"
$ADPFile = $workFolder + "ADP.json"
$ODSName = "SQLTable"
$ResourceGroupName = $NamePrefix + "rg"
$DataFactoryName = $NamePrefix + "df"
$StorageAccountName = $NamePrefix + "sa"
$ContainerName = "adf"
$SQLServerName = $NamePrefix + "sql1"
$ContainerName = "adf"
$SQLServerLogin = "sqllogin1"                              # Login created for SQL Server Administration
$SQLServerLogin3 = "sqllogin3"                             # Login created for Database Administration
$Password = "Password123"
$SQLDatabase = "db1"
$SQLDatabaseTable = "Emp"  
$SQLDatabaseConnectionString = "jdbc:sqlserver://$SQLServerName.database.windows.net;user=$SQLServerLogin3@$SQLServerName;password=$Password;database=$SQLDatabase"
$LoginScript1 = Get-Content ($WorkFolder + "CreateSSLogin1.txt")
$LoginScript3 = Get-Content ($WorkFolder + "CreateSSLogin3.txt")
$TableScript = Get-Content ($WorkFolder + "SQLTable.txt")
		
### Login to Azure
Login-AzureRmAccount -ServicePrincipal -TenantId $TenantID -ApplicationID $ApplicationID -CertificateThumbprint $CertificateThumbprint
Select-AzureRMSubscription -SubscriptionID $SubscriptionID -TenantID $TenantID

### Create Azure Resource Group & Data Factory
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
$DF = New-AzureRmDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName –Location $Location
		
### Create Storage Account
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
       
### Create Azure SQL Server, Database & Table
$PWSQL = ConvertTo-SecureString -String $Password -AsPlainText -Force
$SQLCredential = New-Object System.Management.Automation.PSCredential($SQLServerLogin,$PWSQL)
New-AzureRMSQLServer -ResourceGroupName $ResourceGroupName -Location $Location -Servername $SQLServerName -SQLAdministratorCredentials $SQLCredential -ServerVersion "12.0"
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIP1" -StartIpAddress $ExternalIP -EndIPAddress $ExternalIPNew        
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

### Copy Configuration Files to Storage Blob
$Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
New-AzureStorageContainer -Name $ContainerName -Context $Context
Get-Childitem $WorkFolder -File -Recurse | Set-AzureStorageBlobContent -Container $ContainerName -Context $Context -Force

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

#Start-Sleep 600 ; Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force
