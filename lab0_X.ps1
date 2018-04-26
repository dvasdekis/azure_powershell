### Create Variables
$SubscriptionID = “MSDN Platforms”
$WorkFolder = "C:\LabTemp\"
$namePrefix = “IN”			# Replace “IN” with your initials
$namePrefix = $namePrefix.ToLower() + “55224a” + (Get-Date -Format “mmss") 
$resourceGroupName = $namePrefix + "rg“
$Location = "NORTHEUROPE“
$StorageAccountName = $namePrefix + "sa"
$azcopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy" 
$BlobContainerName = "55224a"

### Install Azure PowerShell
# Find-Module AzureRM -IncludeDependencies | Install-Module

### Get a list of Azure PowerShell cmdlets
# Get-Command –Module AzureRM ; Get-Command –Module AzureRM | Measure-Object

### Login to Azure
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $SubscriptionID | Select-AzureRmSubscription

### Create Resource Group, Storage Account and Container
$RG = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location
$SA = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 

### Verify Login conext, storage account and container
Get-AzureRmContext
Get-AzurermStorageAccount
Get-AzureStorageContainer -Context $StorageAccountContext

### Upload data to the Blob
$azcopycmd = "cmd.exe /C '$azcopyPath\azcopy.exe' /Y /NC:2 /Source:'$workFolder' /Dest:'https://$StorageAccountName.blob.core.windows.net/$BlobContainerName/' /DestKey:$StorageAccountKey"
Invoke-Expression -Command:$azcopycmd

### Delete the Resource Group and all the items associated with it
# Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force
$DD = Get-Date -Format "yyyy-MM-dd"
$YY = Get-Date -Format "yyyy"
$AzureUsage = Get-UsageAggregates -ReportedStartTime $YY"-01-01" -ReportedEndTime $DD -AggregationGranularity "Hourly" -ShowDetails $True
$AzureUsage.UsageAggregations.Properties | `
            Select-Object `
            @{n='SubscriptionId';e={$subscriptionId}}, `
            UsageStartTime, `
            UsageEndTime, `
            MeterName, `
            MeterCategory, `
            MeterRegion, `
            Unit, `
            Quantity, `
            InstanceData `
            | Export-CSV -LiteralPath $WorkFolder"AzureUsageData.csv"


