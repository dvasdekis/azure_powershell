### Create Variables
$WorkFolder = "C:\Labfiles\"
$namePrefix = "in"			# Replace “in” with your initials
$namePrefix = $namePrefix.ToLower() + “55224a” + (Get-Date -Format “mmss") 
$resourceGroupName = $namePrefix + "rg"
$Location = "EASTUS"
$StorageAccountName = $namePrefix + "sa"
$BlobContainerName = "55224a"

### Add AZ Interactive Module   (Not Required)
### az component update --add interactive
### az interactive

### Login to Azure      (Not Required for Azure Cloud Shell)
az login 		        (Note:  You will be prompted to use a web browser to enter an authentication code at https://aka.ms/devicelogin)

### List existing Resource Groups and create a new one
az group list
az group create -n $ResourceGroupName -l $Location

### Create a Storage Account       (Note:  The az storage account check-name command can be used to verify that no one else is using a storage account name.)
az storage account create -n $StorageAccountName -l $Location -g $ResourceGroupName --sku standard_lrs          

### Use the connection string parameter to get the account key for your new storage account:  
az storage account show-connection-string -n $StorageAccountName -g $ResourceGroupName 

Use the information from the previous command to configure the new storage account as your default for this session.  The connection string should be enclosed in double quotes.
$CS = <ConnectionString>

### Create a container in the default storage account:  
az storage container create -n $BlobContainerName --connection-string $CS

### Use the Azure Portal to verify the create of the new resource group, storage account, and container.
###Delete the resource group and verify that the storage account and container were also removed:  
az group delete -n $ResourceGroupName

