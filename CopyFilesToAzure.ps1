### Create Blob and copy files to it from file system
$SubscriptionName = "MSDN Platforms"                                     # This variable should be assigned your "Subscription Name"
$workFolder = "C:\Labfiles\"                                           
$TempFolder = "C:\Temp\"
$Location = "eastus"
$namePrefix = "aa" + (Get-Date -Format "HHmmss")                         # Replace "aa" with your initials
$TimeZone = "Eastern Standard Time"
$ResourceGroupName = $namePrefix + "rg"
$StorageAccountName = $namePrefix.tolower() + "sa"                     # Must be lower case

### Login to Azure
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account & Azure Share
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $location -Type Standard_RAGRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
$AS = New-AzureStorageShare "labfiles" -Context $StorageAccountContext
 
### Copy local file to Azure Share and verify
New-AzureStorageDirectory -Share $AS -Path txtfiles
Get-ChildItem $WorkFolder"*.txt" -Recurse | Set-AzureStorageFileContent -Share $AS -Path /txtfiles -Force
Get-AzureStorageFile -Sharename labfiles -Context $StorageAccountContext
 
### Copy Azure Share file to local directory and verify
Get-AzureStorageFileContent -Share $AS -Path password.txt -Destination $TempFolder -Force
Get-ChildItem $TempFolder 

### Remove Resource Group and all objects associated with it
# Remove-AzureRMResourceGroup -Name $resourceGroupName -Force
