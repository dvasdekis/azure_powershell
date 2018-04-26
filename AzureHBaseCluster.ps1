### Process an interactive job using HDInsight (Spark)
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                       # Change to match your Azure subscription ID
$namePrefix = "in"                                                                       # Change the name prefix to use your initials 
$WorkFolder = "C:\Labfiles\Lab2\" ; $StatusFolder = "C:\Labfiles\" ; New-Item -Path $WorkFolder, $StatusFolder -ItemType Directory -Force -ErrorAction "SilentlyContinue"
$JSONOriginal = $WorkFolder + "createstreamanalyticsjob.tmp"
$JSONNew = $WorkFolder + "createstreamanalyticsjob.json"
$namePrefix = $namePrefix.ToLower() + (Get-Date -Format "HHmmss")
$resourceGroupName = $namePrefix + "rg"
$Location = "EASTUS"
$ClusterName = $namePrefix + "hdi"
$AdminName="clusteradmin"
$AdminPassword="P@ssword123"
$SSHName = "sshadmin"
$SSHPassword = "P@assword123"
$StorageAccountName = $namePrefix + "sa"
$StorageContainerName = $namePrefix + "sc" 

### Record the start time to your log file
$logFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Azure Hbase Cluster" > $StatusFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $StatusFolder$logFilePrefix$logFileSuffix

### Login to Azure
Login-AzureRmAccount
$ID = (Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription)

### Create Resource Group, Storage Account and Blob
New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 

### Copy local files to Azure Blob
# Get-Childitem $WorkFolder"*.csv" | Set-AzureStorageBlobContent -Container $BlobContainerName -Context $StorageAccountContext -Force

### Configure Cluster Resources
$AdminPW = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$AdminCred = New-Object System.Management.Automation.PSCredential ($AdminName, $AdminPW)
$SSHPW = ConvertTo-SecureString $SSHPassword -AsPlainText -Force
$SSHCred = New-Object System.Management.Automation.PSCredential ($SSHName, $SSHPW)

New-AzureRmHDInsightCluster `
    -ClusterName $clusterName `
    -ResourceGroupName $resourceGroupName `
    -HttpCredential $AdminCred `
    -Location $Location `
    -DefaultStorageAccountName "$StorageAccountName.blob.core.windows.net" `
    -DefaultStorageAccountKey $StorageAccountKey `
    -DefaultStorageContainer $StorageContainerName  `
    -ClusterSizeInNodes 1 `
    -ClusterType Hadoop `
    -OSType Linux `
    -Version "3.5" `
    -SshCredential $SSHCred

Copy-Item $JSONOriginal $JSONNew -Force
(Get-Content $JSONNew) -Replace '<accountname>', $StorageAccountName | Set-Content $JSONNew
(Get-Content $JSONNew) -Replace '<accountkey>', $StorageAccountKey | Set-Content $JSONNew
New-AzureRMStreamAnalyticsJob -ResourceGroupName $ResourceGroupName -Name $NamePrefix"job" -File $WorkFolder"createstreamanalyticsjob.json" -Force

### Delete Resources and log end time of script
$EndTime = Get-Date ; $et = $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $tempFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $tempFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $tempFolder$logFilePrefix$logFileSuffix -NewName $tempFolder"Time"$et$logFileSuffix
# Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
