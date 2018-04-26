### Create Blob and copy files to it from file system
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionID = "MSDN Platforms"                                     # This variable should be assigned your "Subscription Name"
$workFolder = "C:\Labfiles\"                                           
$TempFolder = "C:\Temp\"
New-Item -ItemType Directory -Path $WorkFolder, $TempFolder -Force -ErrorAction SilentlyContinue
$Location = "eastus"
$namePrefix = "aa" + (Get-Date -Format "HHmmss")                         # Replace "aa" with your initials
$TimeZone = "Eastern Standard Time"
$ResourceGroupName = $namePrefix + "rg"
$StorageAccountName = $namePrefix.tolower() + "sa"                     # Must be lower case
$BlobContainerName = "labfiles"

### Login to Azure
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $SubscriptionID | Select-AzureRmSubscription

### Create Resource Group, Storage Account & Azure Blob
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $location -Type Standard_RAGRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 
 
### Copy local files to Azure Blob and verify
### The list of files can be filtered based on the last modified date   (Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-1)})
Get-Childitem $WorkFolder"*.txt" -Recurse | Set-AzureStorageBlobContent -Container $BlobContainerName -Context $StorageAccountContext -Force
Get-AzureStorageBlob -Container $BlobContainerName -Context $StorageAccountContext | Format-Table Name,Length
 
### Copy Azure Blob files to local directory and verify
Get-AzureStorageBlob -Container $BlobContainerName -Context $StorageAccountContext | Get-AzureStorageBlobContent -Destination $TempFolder
Get-ChildItem $TempFolder"*.txt" 

### Remove Resource Group and all objects associated with it
# Remove-AzureRMResourceGroup -Name $resourceGroupName -Force
