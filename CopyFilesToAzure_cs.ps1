### Create Blob and copy files to it from file system
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                            # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
Set-Location F:\Labfiles
$WorkFolder = "F:\Labfiles\"                                           
$TempFolder = "F:\Temp\"
$Location = "eastus"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                              # Replace "in" with your initials
$TimeZone = "Eastern Standard Time"
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix.tolower() + "sa"                     # Must be lower case

### Login to Azure
# Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

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
