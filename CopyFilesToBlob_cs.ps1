### Create Blob and copy files to it from file system
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                            # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
Set-Location F:\Labfiles
$WorkFolder = "F:\Labfiles\"                                           
$TempFolder = "F:\Temp\"
New-Item -ItemType Directory -Path $WorkFolder, $TempFolder -Force -ErrorAction SilentlyContinue
$Location = "EASTUS"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                              # Replace "in" with your initials
$TimeZone = "Eastern Standard Time"
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix.ToLower() + "sa"                     # Must be lower case
$BlobContainerName = "labfiles"

### Login to Azure & Select Azure Subscription
# Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account & Azure Blob
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $location -Type Standard_RAGRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 
 
### Copy local files to Azure Blob and verify
### The list of files can be filtered based on the last modified date   (Where-Object {$_.LastWriteTime -GT (Get-Date).AddDays(-1)})
Get-ChildItem $WorkFolder"*.txt" -Recurse | Set-AzureStorageBlobContent -Container $BlobContainerName -Context $StorageAccountContext -Force
Get-AzureStorageBlob -Container $BlobContainerName -Context $StorageAccountContext | Format-Table Name,Length
 
### Copy Azure Blob files to local directory and verify
Get-AzureStorageBlob -Container $BlobContainerName -Context $StorageAccountContext | Get-AzureStorageBlobContent -Destination $TempFolder -Force
Get-ChildItem $TempFolder"*.txt" 

### Remove Resource Group and all objects associated with it
# Remove-AzureRMResourceGroup -Name $resourceGroupName -Force
