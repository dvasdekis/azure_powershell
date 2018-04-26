### Create Variables
$WorkFolder = "C:\LabTemp\"
$azcopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy" 
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
az login 		        # (Note:  You will be prompted to use a web browser to enter an authentication code at https://aka.ms/devicelogin)

### List existing Resource Groups and create a new one
az group list
$RG = az group create -n $ResourceGroupName -l $Location

### Create a Storage Account       (Note:  The az storage account check-name command can be used to verify that no one else is using a storage account name.)
$SA = az storage account create -n $StorageAccountName -l $Location -g $ResourceGroupName --sku standard_lrs          

### Get the connection string, Storage Account Key and SAS Token for the new Storage Account:  
$ExpireDate = ((get-date).adddays(60)).ToString("yyyy-MM-dd'T'HH:mm'Z'")
$StorageAccountCS = (az storage account show-connection-string -n $StorageAccountName -g $ResourceGroupName | ConvertFrom-Json).ConnectionString
$StorageAccountKey = (az storage account keys list -n $StorageAccountName -g $ResourceGroupName | ConvertFrom-Json)[0].Value
$StorageAccountToken = az storage account generate-sas --expiry $ExpireDate --services bf --resource-types sco --permissions cdluw --account-name $StorageAccountName
# az storage blob url --container-name $BlobContainerName --name $BlobContainerName --connection-string $StorageAccountCS


### Create a container in the default Storage Account:  
az storage container create -n $BlobContainerName --connection-string $StorageAccountCS
$SADestination = "https://" + $StorageAccountName + ".blob.core.windows.net/"  + $BlobContainerName + "/"

### Upload data to the Container
$azcopycmd = "cmd.exe /C '$azcopyPath\azcopy.exe' /Y /NC:2 /Source:'$workFolder' /Dest:$SADestination /DestKey:$StorageAccountKey"
Invoke-Expression -Command:$azcopycmd

### Use the Azure Portal to verify the create of the new resource group, storage account, and container.
###Delete the resource group and verify that the storage account and container were also removed:  
# az group delete -n $ResourceGroupName

