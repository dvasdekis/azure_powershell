### Process a batch job using HDInsight 
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                                 # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
Set-Location F:\Labfiles
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$WorkFolder = "F:\Labfiles\Lab1\" ; $StatusFolder = "F:\Labfiles\" ; New-Item -Path $WorkFolder, $StatusFolder -ItemType Directory -Force -ErrorAction "SilentlyContinue"
$TableFile = "F:\Labfiles\Lab1\CreateAvgDelaysTable.txt"
$TableScript = Get-Content $TableFile
$LoginFile = "F:\Labfiles\Lab1\CreateSSLogin.txt"
$LoginScript = Get-Content $LoginFile
$Location = "EASTUS"
$DataLocation = "NORTHEUROPE"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                           # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"
$SQLServerName = $NamePrefix + "sql1"
$SQLServerLogin = "sqllogin1"
$SQLServerLogin3 = "sqllogin3"
$SQLServerPassword = "Password123"
$SQLDatabase = "db1"
$SQLDatabaseTable = "AvgDelays"  
$sqlDatabaseConnectionString = "jdbF:sqlserver://$SQLServerName.database.windows.net;user=$SQLServerLogin3@$SQLServerName;password=$SQLServerPassword;database=$SQLDatabase"
$HDInsightClusterName = $NamePrefix + "hdi"
$BlobContainerName = $HDInsightClusterName
$httpUserName = "admin"
$httpPassword = "Cr3d3nti@l"
$hqlScriptFile = "wasbs://$BlobContainerName@$StorageAccountName.blob.core.windows.net/flightdelays.hql" 

### Log start time of script
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Azure Batch Processing" > $StatusFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $StatusFolder$LogFilePrefix$LogFileSuffix

### Login to Azure & Select Azure Subscription
# Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account and Blob
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $DataLocation -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 

### Create Azure SQL Server, Database & Table
$PWSQL = ConvertTo-SecureString -String $SQLServerPassword -AsPlainText -Force
$SQLCredential = New-Object System.Management.Automation.PSCredential($SQLServerLogin,$PWSQL)
New-AzureRMSQLServer -ResourceGroupName $ResourceGroupName -Location $Location -Servername $SQLServerName -SQLAdministratorCredentials $SQLCredential -ServerVersion "12.0"
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIP1" -StartIpAddress $ExternalIP -EndIPAddress $ExternalIP        
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -AllowAllAzureIPs
New-AzureRmSQLDatabase -ResourceGroupName $ResourceGroupName -Servername $SQLServerName -DatabaseName $SQLDatabase
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=master;User ID=$SQLServerLogin@$SQLServerName;Password=$SQLServerPassword;Trusted_Connection=False;Encrypt=True;"
$SAConnection=New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection.Open()
$CreateTable= New-Object System.Data.SqlClient.SqlCommand($LoginScript,$SAConnection)
$CreateTable.ExecuteNonQuery()
$SAConnection.Close()
$ConnectionString = "Server=tcp:$SQLServerName.database.windows.net;Database=db1;User ID=$SQLServerLogin@$SQLServerName;Password=$SQLServerPassword;Trusted_Connection=False;Encrypt=True;"
$SAConnection=New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$SAConnection.Open()
$CreateTable= New-Object System.Data.SqlClient.SqlCommand($TableScript,$SAConnection)
$CreateTable.ExecuteNonQuery()
$SAConnection.Close()

### Create HDInsight Cluster
$PW = ConvertTo-SecureString -String $httpPassword -AsPlainText -Force
$httpCredential = New-Object System.Management.Automation.PSCredential($httpUserName,$PW)
New-AzureRmHDInsightCluster `
    -ResourceGroupName $ResourceGroupName `
    -ClusterName $HDInsightClusterName `
    -Location $DataLocation `
    -ClusterType Hadoop `
    -OSType Windows `
    -ClusterSizeInNodes 2 `
    -HttpCredential $httpCredential `
    -DefaultStorageAccountName "$StorageAccountName.blob.core.windows.net" `
    -DefaultStorageAccountKey $StorageAccountKey `
    -DefaultStorageContainer $BlobContainerName 
$HDIExternalIP = (Resolve-DNSName $HDInsightClusterName".azurehdinsight.net" | Select-Object IP4Address).getvalue(1)
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName $HDInsightClusterName -StartIpAddress $HDIExternalIP.IP4Address -EndIPAddress $HDIExternalIP.IP4Address        

### Upload data to the Blob
Get-ChildItem $WorkFolder -Recurse | Set-AzureStorageBlobContent -Container $BlobContainerName -Context $StorageAccountContext -Force

### Submit the Hive Job
Use-AzureRmHDInsightCluster -ClusterName $HDInsightClusterName -HttpCredential $httpCredential -Verbose
New-AzureRmHDInsightHiveJobDefinition -StatusFolder $StatusFolder -File $hqlScriptFile | Start-AzureRmHDInsightJob -ClusterName $HDInsightClusterName -HttpCredential $httpCredential -Verbose

### Submit the Sqoop Job
$exportDir = "wasbs://$BlobContainerName@$StorageAccountName.blob.core.windows.net/2016flightdata"
$sqoopDef = New-AzureRmHDInsightSqoopJobDefinition -Command "export --connect $sqlDatabaseConnectionString --table $SQLDatabaseTable --export-dir $exportDir --input-fields-terminated-by \0054 --input-optionally-enclosed-by \0042 --verbose "
$sqoopJob = Start-AzureRmHDInsightJob -ResourceGroupName $resourceGroupName -ClusterName $hdinsightClusterName -HttpCredential $httpCredential -JobDefinition $sqoopDef -Verbose
Wait-AzureRmHDInsightJob -ResourceGroupName $ResourceGroupName -ClusterName $HDInsightClusterName -HttpCredential $httpCredential -TimeoutInSeconds 3600 -Job $sqoopJob.JobId

Get-AzureRmHDInsightJobOutput `
        -ResourceGroupName $ResourceGroupName `
        -ClusterName $hdinsightClusterName `
        -HttpCredential $httpCredential `
        -DefaultContainer $BlobContainerName `
        -DefaultStorageAccountName $StorageAccountName `
        -DefaultStorageAccountKey $StorageAccountKey `
        -JobId $sqoopJob.JobId `
        -DisplayOutputType StandardError

### Delete Cluster and log end time of script
Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $StatusFolder$LogFilePrefix$LogFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $StatusFolder$LogFilePrefix$LogFileSuffix 
Rename-Item -Path $StatusFolder$LogFilePrefix$LogFileSuffix -NewName $et$LogFileSuffix

