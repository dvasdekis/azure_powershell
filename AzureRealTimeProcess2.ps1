### Process a Stream Analytics job
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                     # Change to match your Azure subscription ID
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                             # Change the name prefix to use your initials 
$WorkFolder = "C:\Labfiles\Lab2\" ; $StatusFolder = "C:\Labfiles\" 
$TMPJob = $WorkFolder + "createstreamanalyticsjob.tmp"
$JSONJob = $WorkFolder + "createstreamanalyticsjob.json"
$TMPInput = $WorkFolder + "createstreamanalyticsinput.tmp"
$JSONInput = $WorkFolder + "createstreamanalyticsinput.json"
$TMPOutput = $WorkFolder + "createstreamanalyticsoutput.tmp"
$JSONOutput = $WorkFolder + "createstreamanalyticsoutput.json"
$TMPTransformation = $WorkFolder + "createstreamanalyticstransformation.tmp"
$JSONTransformation = $WorkFolder + "createstreamanalyticstransformation.json"
$Location = "EASTUS"
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"
$BlobContainerName = $NamePrefix + "blob"
$NamespaceName = $NamePrefix + "ns"
$EventHubName = $NamePrefix + "eh"
$ConsumerGroupName = $NamePrefix + "cg" 
$SAJobName = $NamePrefix + "job"
$SAInputName = $NamePrefix + "input"
$SAOutputName = $NamePrefix + "output"
$URI = "$NamespaceName.servicebus.windows.net/$EventHubName/publishers/$ConsumerGroupName"
$SQLServerName = $NamePrefix + "sql1"
$SQLServerLogin = "sqllogin1"
$SQLServerLogin3 = "sqllogin3"
$SQLServerPassword = "Password123"
$SQLDatabase = "db1"
$SQLTable = "ohioweather"  
$sqlDatabaseConnectionString = "jdbc:sqlserver://$SQLServerName.database.windows.net;user=$SQLServerLogin3@$SQLServerName;password=$SQLServerPassword;database=$SQLDatabase"
$TableFile = $WorkFolder + "OhioWeatherTable.txt"
$TableScript = Get-Content $TableFile
$LoginFile = $WorkFolder + "CreateSSLogin.txt"
$LoginScript = Get-Content $LoginFile

### Record the start time to your log file
$logFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Azure Real Time Processing (SQL)" > $StatusFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $StatusFolder$logFilePrefix$logFileSuffix

### Login to Azure
Login-AzureRmAccount
$ID = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account and Blob
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
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

### Create Event Hub
New-AzureRmEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -Location $Location
New-AzureRmEventHubAuthorizationRule -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -AuthorizationRuleName $NameSpaceName"Rule1" -Rights @("Listen","Send")
$NamespaceKey = (Get-AzureRmEventHubKey -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -AuthorizationRuleName $NamespaceName"Rule1")
New-AzureRmEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -Location $Location -MessageRetentionInDays "3" -PartitionCount "3"
New-AzureRmEventHubAuthorizationRule -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -AuthorizationRuleName $EventHubName"Rule1" -Rights @("Listen","Send")
$HubKey = Get-AzureRmEventHubKey -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -AuthorizationRuleName $EventHubName"Rule1"
New-AzureRMEventHubConsumerGroup -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -ConsumerGroupName $ConsumerGroupName 

### Create Stream Analytics Job with Input, Output & Transformation components  (Note: The "createstreamanalyticsjob.json" file creates input, query & output components that are later modified or deleted)
Register-AzureRmResourceProvider -ProviderNamespace 'Microsoft.StreamAnalytics'               # This needs to be run only once
Copy-Item $TMPJob $JSONJob -Force
(Get-Content $JSONJob) -Replace 'samplelocation', $Location | Set-Content $JSONJob
New-AzureRMStreamAnalyticsJob -ResourceGroupName $ResourceGroupName -Name $SAJobName -File $JSONJob -Force
# Stream Analytics Input
Get-AzureRmStreamAnalyticsInput -ResourceGroupName $ResourceGroupName -JobName $SAJobName | Remove-AzureRmStreamAnalyticsinput
Copy-Item $TMPInput $JSONInput -Force
(Get-Content $JSONInput) -Replace 'sampleEventHub', $EventHubName | Set-Content $JSONInput
(Get-Content $JSONInput) -Replace 'sampleSAPKey', $Hubkey.PrimaryKey | Set-Content $JSONInput
(Get-Content $JSONInput) -Replace 'sampleNamespace', $NamespaceName | Set-Content $JSONInput
(Get-Content $JSONInput) -Replace '\$Default', $ConsumerGroupName | Set-Content $JSONInput
(Get-Content $JSONInput) -Replace 'sampleSAP', $HubKey.KeyName | Set-Content $JSONInput
New-AzureRmStreamAnalyticsInput -ResourceGroupName $ResourceGroupName -JobName $SAJobName -Name $SAInputName -File $JSONInput
# Stream Analytics Output
Get-AzureRmStreamAnalyticsOutput -ResourceGroupName $ResourceGroupName -JobName $SAJobName | Remove-AzureRmStreamAnalyticsOutput
Copy-Item $TMPOutput $JSONOutput -Force
(Get-Content $JSONOutput) -Replace 'sampleserver', $SQLServerName | Set-Content $JSONOutput
(Get-Content $JSONOutput) -Replace 'sampledatabase', $SQLDatabase | Set-Content $JSONOutput
(Get-Content $JSONOutput) -Replace 'sampletable', $SQLTable | Set-Content $JSONOutput
(Get-Content $JSONOutput) -Replace 'sampleuser@sqlserver', "$SQLServerLogin3@$SQLServerName.database.windows.net" | Set-Content $JSONOutput
(Get-Content $JSONOutput) -Replace 'samplepassword', $SQLServerPassword | Set-Content $JSONOutput
New-AzureRmStreamAnalyticsOutput -ResourceGroupName $ResourceGroupName -JobName $SAJobName -Name $SAOutputName -File $JSONOutput
# Stream Analytics Transformation
Copy-Item $TMPTransformation $JSONTransformation -Force
(Get-Content $JSONTransformation) -Replace 'select \* from samplequery', "Select Date, VAlue, Anomaly From $SAInputName" | Set-Content $JSONTransformation
New-AzureRmStreamAnalyticsTransformation -ResourceGroupName $ResourceGroupName -JobName $SAJobName -Name "Transformation1" -File $JSONTransformation -Force

### Send Messages to EventHub
Start-AzureRMStreamAnalyticsJob -ResourceGroupName $ResourceGroupName -Name $SAJobName -Verbose
$SASToken = Get-AzureEHSASToken -URI $URI -AccessPolicyName $HubKey.KeyName -AccessPolicyKey $HubKey.PrimaryKey
Remove-Item $WorkFolder"OhioWeather.txt" -Force -ErrorAction SilentlyContinue
Import-CSV $WorkFolder"OhioWeather.csv" | `
Foreach-Object { $Message = "{" + "'Date':'" + $_.Date + "', 'Value':'" + $_.Value + "', 'Anomaly':'" + $_.Anomaly + "'}" ; `
$Message | Add-Content $WorkFolder"OhioWeather.txt" -Encoding UTF8 ; `
Send-AzureEHDatagram -URI $URI -SASToken $SASToken -DataGram $Message}
Stop-AzureRMStreamAnalyticsJob -ResourceGroupName $ResourceGroupName -Name $SAJobName -Verbose

### Delete Resources and record the end time to your log file
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $StatusFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $StatusFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $StatusFolder$logFilePrefix$logFileSuffix -NewName $et$logFileSuffix
### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force