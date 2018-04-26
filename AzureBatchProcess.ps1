### Process a batch job using HDInsight 
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                     # Change to match your Azure subscription ID
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$namePrefix = "aa"                                                                       # Change the name prefix variable to use your initials 
$WorkFolder = "C:\Labfiles\Lab1\" ; $StatusFolder = "C:\Labfiles\" ; New-Item -Path $WorkFolder, $StatusFolder -ItemType Directory -Force -ErrorAction "SilentlyContinue"
$TableFile = "C:\Labfiles\Lab1\CreateAvgDelaysTable.txt"
$TableScript = Get-Content $TableFile
$LoginFile = "C:\Labfiles\Lab1\CreateSSLogin.txt"
$LoginScript = Get-Content $LoginFile
$azcopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy" 
$namePrefix = $namePrefix.ToLower() + (Get-Date -Format "HHmmss")
$resourceGroupName = $namePrefix + "rg"
$Location = "EASTUS"
$SQLServerName = $namePrefix + "sql1"
$SQLServerLogin = "sqllogin1"
$SQLServerLogin3 = "sqllogin3"
$SQLServerPassword = "Password123"
$SQLDatabase = "db1"
$SQLDatabaseTable = "AvgDelays"  
$sqlDatabaseConnectionString = "jdbc:sqlserver://$SQLServerName.database.windows.net;user=$SQLServerLogin3@$SQLServerName;password=$SQLServerPassword;database=$SQLDatabase"
$HDInsightClusterName = $namePrefix + "hdi"
$httpUserName = "admin"
$httpPassword = "Cr3d3nti@l"
$StorageAccountName = $namePrefix + "sa"
$BlobContainerName = $HDInsightClusterName 
$hqlScriptFile = "wasbs://$BlobContainerName@$StorageAccountName.blob.core.windows.net/flightdelays.hql" 

### Log start time of script
$logFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Azure Batch Processing" > $StatusFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $StatusFolder$logFilePrefix$logFileSuffix

### Login to Azure
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account and Blob
New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 

### Create Azure SQL Server, Database & Table
$PWSQL = ConvertTo-SecureString -String $SQLServerPassword -AsPlainText -Force
$SQLCredential = New-Object System.Management.Automation.PSCredential($SQLServerLogin,$PWSQL)
New-AzureRMSQLServer -ResourceGroupName $ResourceGroupName -Location $Location -Servername $SQLServerName -SQLAdministratorCredentials $SQLCredential -ServerVersion "12.0"
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -FirewallRuleName "ClientIP1" -StartIpAddress $ExternalIP -EndIPAddress $ExternalIP        
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -AllowAllAzureIPs
New-AzureRmSQLDatabase -ResourceGroupName $resourceGroupName -Servername $SQLServerName -DatabaseName $SQLDatabase
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
    -ResourceGroupName $resourceGroupName `
    -ClusterName $HDInsightClusterName `
    -Location $location `
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
$azcopycmd = "cmd.exe /C '$azcopyPath\azcopy.exe' /S /Y /NC:2 /Source:'$workFolder' /Dest:'https://$StorageAccountName.blob.core.windows.net/$BlobContainerName/' /DestKey:$StorageAccountKey"
Invoke-Expression -Command:$azcopycmd

### Submit the Hive job
Use-AzureRmHDInsightCluster -ClusterName $HDInsightClusterName -HttpCredential $httpCredential -Verbose
New-AzureRmHDInsightHiveJobDefinition -StatusFolder $StatusFolder -File $hqlScriptFile | Start-AzureRmHDInsightJob -ClusterName $HDInsightClusterName -HttpCredential $httpCredential -Verbose

### Submit the Sqoop job
$exportDir = "wasbs://$BlobContainerName@$StorageAccountName.blob.core.windows.net/2016flightdata"
$sqoopDef = New-AzureRmHDInsightSqoopJobDefinition -Command "export --connect $sqlDatabaseConnectionString --table $SQLDatabaseTable --export-dir $exportDir --input-fields-terminated-by \0054 --input-optionally-enclosed-by \0042 --verbose "
$sqoopJob = Start-AzureRmHDInsightJob -ResourceGroupName $ResourceGroupName -ClusterName $HDInsightClusterName -HttpCredential $httpCredential -JobDefinition $sqoopDef -Verbose
Wait-AzureRmHDInsightJob -ResourceGroupName $resourceGroupName -ClusterName $HDInsightClusterName -HttpCredential $httpCredential -TimeoutInSeconds 3600 -Job $sqoopJob.JobId

Get-AzureRmHDInsightJobOutput `
        -ResourceGroupName $ResourceGroupName `
        -ClusterName $HDInsightClusterName `
        -HttpCredential $httpCredential `
        -DefaultContainer $BlobContainerName `
        -DefaultStorageAccountName $StorageAccountName `
        -DefaultStorageAccountKey $StorageAccountKey `
        -JobId $sqoopJob.JobId `
        -DisplayOutputType StandardError

### Delete Cluster and log end time of script
Remove-AzureRMResourceGroup -Name $resourceGroupName -Force
$EndTime = Get-Date ; $et = "Time" + EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $StatusFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $StatusFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $StatusFolder$logFilePrefix$logFileSuffix -NewName $et$logFileSuffix

