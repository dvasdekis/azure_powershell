### Process a Stream Analytics job
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                       # Change to match your Azure subscription ID
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                               # Change the name prefix to use your initials 
$WorkFolder = "C:\Labfiles\Lab2\" ; $StatusFolder = "C:\Labfiles\" 
$JSONJob = $WorkFolder + "createstreamanalyticsjob.json"
$TMPInput = $WorkFolder + "createstreamanalyticsinput.tmp"
$JSONInput = $WorkFolder + "createstreamanalyticsinput.json"
$TMPOutput = $WorkFolder + "createstreamanalyticsoutput.tmp"
$JSONOutput = $WorkFolder + "createstreamanalyticsoutput.json"
$Location = "EASTUS"
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"
$BlobContainerName = $NamePrefix + "blob"
$NamespaceName = $NamePrefix + "ns"
$EventHubName = $NamePrefix + "eh"
$ConsumerGroupName = $NamePrefix + "cg" 
$SAJobName = $NamePrefix + "job"
$SAInputName = $NamePrefix + "input"
$URI = "$NamespaceName.servicebus.windows.net/$EventHubName/publishers/$ConsumerGroupName"

### Record the start time to your log file
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Azure Real Time Processing" > $StatusFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $StatusFolder$LogFilePrefix$LogFileSuffix

### Login to Azure
Login-AzureRmAccount
$ID = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account and Blob
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 

### Create Event Hub
# New-AzureRmResourceGroupDeployment -Name "CreateEventHub1" -ResourceGroupName $ResourceGroupName -eventHubNamespaceName $NamespaceName"1" -eventHubName $EventHubName"1" -BlobContainerName $BlobContainerName -DestinationStorageAccountResourceID $StorageAccount.id -TemplateFile $WorkFolder"createeventhub.json"
# Add-AzureRmLogProfile -Name $namePrefix"log" -StorageAccountId $StorageAccount.Id -serviceBusRuleId /subscriptions/s1/resourceGroups/Default-ServiceBus-EastUS/providers/Microsoft.ServiceBus/namespaces/mytestSB/authorizationrules/RootManageSharedAccessKey -Locations $Location -RetentionInDays 90
New-AzureRmEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -Location $Location
New-AzureRmEventHubAuthorizationRule -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -AuthorizationRuleName $NameSpaceName"Rule1" -Rights @("Listen","Send")
$NamespaceKey = (Get-AzureRmEventHubKey -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -AuthorizationRuleName $NamespaceName"Rule1")
New-AzureRmEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -Location $Location -MessageRetentionInDays "3" -PartitionCount "3"
New-AzureRmEventHubAuthorizationRule -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -AuthorizationRuleName $EventHubName"Rule1" -Rights @("Listen","Send")
$HubKey = Get-AzureRmEventHubKey -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -AuthorizationRuleName $EventHubName"Rule1"
New-AzureRMEventHubConsumerGroup -ResourceGroupName $ResourceGroupName -NamespaceName $NamespaceName -EventHubName $EventHubName -ConsumerGroupName $ConsumerGroupName 

### Send Messages to EventHub
$SASToken = Get-AzureEHSASToken -URI $URI -AccessPolicyName $HubKey.KeyName -AccessPolicyKey $HubKey.PrimaryKey
Remove-Item $WorkFolder"OhioWeather.txt" -Force -ErrorAction SilentlyContinue
Import-CSV $WorkFolder"OhioWeather.csv" | `
Foreach-Object { $Message = "{" + "'Date':'" + $_.Date + "', 'Value':'" + $_.Value + "', 'Anomaly':'" + $_.Anomaly + "'}" ; `
$Message | Add-Content $WorkFolder"OhioWeather.txt" -Encoding UTF8 ; `
Send-AzureEHDatagram -URI $URI -SASToken $SASToken -DataGram $Message}

### Delete Resources and record the end time to your log file
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $StatusFolder$LogFilePrefix$LogFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $StatusFolder$LogFilePrefix$LogFileSuffix 
Rename-Item -Path $StatusFolder$LogFilePrefix$LogFileSuffix -NewName $et$LogFileSuffix
### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
