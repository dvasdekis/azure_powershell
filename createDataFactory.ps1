### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionID = "MSDN Platforms"
$TempFolder = "C:\Tmp\" ; New-Item -Path $TempFolder -ItemType Directory -Force -ErrorAction "Continue"
$WorkFolder = "C:\Work\" ; New-Item -Path $WorkFolder -ItemType Directory -Force -ErrorAction "Continue"
$SLSFileOriginal = $workFolder + "StorageLinkedServiceOriginal.json"
$SLSFile = $workFolder + "StorageLinkedService.json"
$HLSFile = $workFolder + "HDInsightOnDemandLinkedService.json"
$IDSFile = $workFolder + "InputTable.json"
$ODSFile = $workFolder + "OutputTable.json"
$ADFFileOriginal = $workFolder + "ADFPipelineOriginal.json"
$ADFFile = $workFolder + "ADFPipeline.json"
$InputFile = $workFolder + "Input.log"
$azcopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy" 
$namePrefix = "nyc" + (Get-Date -Format "HHmm")
$ResourceGroupName = $namePrefix + "rg"
$DataFactoryName = $namePrefix + "df"
$StorageAccountName = $namePrefix + "sa"
$Location = "EASTUS"

### Log start time of script
$logFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Create Data Factory" > $tempFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $tempFolder$logFilePrefix$logFileSuffix

### Login to Azure
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $SubscriptionID | Select-AzureRmSubscription

### Create Azure Resource Group & Data Factory
New-AzureRmResourceGroup -Name $resourceGroupName  -Location $Location
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.DataFactory
New-AzureRmDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName –Location $Location



### Get Storage Account Parameters and configure JSON File

New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
Copy-Item $SLSFileOriginal $SLSFile -Force
(Get-Content $SLSFile) -Replace '<accountname>', $StorageAccountName | Set-Content $SLSFile

(Get-Content $SLSFile) -Replace '<accountkey>', $StorageAccountKey | Set-Content $SLSFile



### Copy Input File to Storage Blob

$azcopycmd = "cmd.exe /C '$azcopyPath\AzCopy.exe' /S /Y /Source:'$WorkFolder' /Dest:'https://$StorageAccountName.blob.core.windows.net/adfgetstarted' /DestKey:$StorageAccountKey"

Invoke-Expression -Command:$azcopycmd


### Create Azure Storage & HDInsight Linked Services
New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $SLSFile

New-AzureRmDataFactoryLinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -File $HLSFile



### Create DataSets

$DF = Get-AzureRmDataFactory -ResourceGroupName $ResourceGroupName -Name $DataFactoryName

New-AzureRmDataFactoryDataset $DF -File $IDSFile

New-AzureRmDataFactoryDataset $DF -File $ODSFile



### Create and Monitor Pipeline

Copy-Item $ADFFileOriginal $ADFFile -Force

(Get-Content $ADFFile) -Replace '<storageaccountname>', $StorageAccountName | Set-Content $ADFFile

New-AzureRmDataFactoryPipeline $DF -File $ADFFile

Get-AzureRmDataFactorySlice $DF -DatasetName AzureBlobOutput -StartDateTime 2016-04-01



### Delete Resources and log end time of script
Write-Output "Delete resouces in 60 seconds" ; Sleep 60 ; Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$LogFilePrefix$LogFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$LogFilePrefix$LogFileSuffix 
Rename-Item -Path $TempFolder$LogFilePrefix$LogFileSuffix -NewName $et$LogFileSuffix
# Remove-Item -Path $workFolder -Force -Recurse -ErrorAction "Continue"
