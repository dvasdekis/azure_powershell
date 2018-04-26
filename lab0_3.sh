### Create Variables and Configure BASH Environment
# bash
# ComputerName=$(hostname)
# echo 127.0.0.1 $ComputerName >> /etc/hosts
sudo su
mkdir ~/clouddrive ; mkdir ~/clouddrive/labfiles ; cd ~/clouddrive/labfiles/
WorkFolder=~/clouddrive/labfiles/
TimeNow=`date +%H%M%S`
MyPrefix=in
NamePrefix=$MyPrefix$TimeNow
ResourceGroupName=$NamePrefix"rg"
StorageAccountName=$NamePrefix"sa"
BlobContainerName=55224a
Location=EASTUS

# Login to Azure
az login

# Configure ARM mode and Create Resource Group
az group create --name $ResourceGroupName --location $Location

# Create Storage Account
az storage account create --name $StorageAccountName --location $Location -g $ResourceGroupName --sku standard_lrs

# Create Blob and File Share
StorageAccountCS=$(az storage account show-connection-string -n $StorageAccountName -g $ResourceGroupName | jq '.[]')
az storage container create --name $BlobContainerName --connection-string $StorageAccountCS
az storage share create --name $BlobContainerName --connection-string $StorageAccountCS

### Upload data to the Blob and File Share
az storage blob upload-batch --source $WorkFolder --pattern "*.zip" --destination $BlobContainerName --connection-string $StorageAccountCS
az storage file upload-batch --source $WorkFolder --pattern "*.ps1" --destination $BlobContainerName --connection-string $StorageAccountCS

# Connect to File Share
mkdir $WorkFolder$NamePrefix
sudo mount -t cifs //in075007sa.file.core.windows.net/55224a $WorkFolder$NamePrefix -o vers=3.0,username=$StorageAccountName,password=$StorageAccoountCS,dir_mode=0777,file_mode=0777,sec=ntlmssp

### Use the Azure Portal to verify the create of the new resource group, storage account, and container.
###Delete the resource group and verify that the storage account and container were also removed:  
# az group delete -n $ResourceGroupName


