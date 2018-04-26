### Create Variables
### wmic os get caption ; get-host
Set-StrictMode -Version 2.0
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                                 # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
Set-Location F:\Labfiles
$WorkFolder="F:\Labfiles\"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                              # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$Location = "EASTUS"
$StorageAccountName = $NamePrefix + "sa"
$BlobContainerName = "55224a"

### Login to Azure                (Not Required for Azure Cloud Shell)
# az login                      # (Note:  You will be prompted to use a web browser to enter an authentication code at https://aka.ms/devicelogin)

### List existing Resource Groups and create a new one
$RG = az group create -n $ResourceGroupName -l $Location

### Create a Storage Account       (Note:  The "az storage account check-name" command can be used to verify that no one else is using a storage account name.)
$SA = az storage account create -n $StorageAccountName -l $Location -g $ResourceGroupName --sku standard_lrs          

### Get the connection string, Storage Account Key and SAS Token for the new Storage Account:  
$ExpireDate = ((get-date).adddays(60)).ToString("yyyy-MM-dd'T'HH:mm'Z'")
$StorageAccountCS = (az storage account show-connection-string -n $StorageAccountName -g $ResourceGroupName | ConvertFrom-Json).ConnectionString
$StorageAccountKey = (az storage account keys list -n $StorageAccountName -g $ResourceGroupName | ConvertFrom-Json)[0].Value
$StorageAccountToken = az storage account generate-sas --expiry $ExpireDate --services bf --resource-types sco --permissions cdluw --account-name $StorageAccountName
# az storage blob url --container-name $BlobContainerName --name $BlobContainerName --connection-string $StorageAccountCS

### Create a Blob and File Share  
az storage container create -n $BlobContainerName --connection-string $StorageAccountCS
az storage share create --name $BlobContainerName --connection-string $StorageAccountCS

### Upload data to the Blob and File Share
az storage blob upload-batch --source $WorkFolder --pattern "*.zip" --destination $BlobContainerName --connection-string $StorageAccountCS
az storage file upload-batch --source $WorkFolder --pattern "*.ps1" --destination $BlobContainerName --connection-string $StorageAccountCS

# Connect to File Share
$FileShare = "\\" + $StorageAccountName + ".file.core.windows.net\" + $BlobContainerName
Net Use Z: $FileShare /u:AZURE\$StorageAccountName $StorageAccountKey

### Use the Azure Portal to verify the create of the new resource group, storage account, and container.
### Delete the resource group and verify that the storage account and container were also removed:  
# az group delete -n $ResourceGroupName
# pip install --user --upgrade numpy, pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azurerm
