### Create Variables
$WorkFolder = "C:\Labfiles\"
$namePrefix = "IN"			# Replace “IN” with your initials
$namePrefix = $namePrefix.ToLower() + “55224a” + (Get-Date -Format “mmss") 
$resourceGroupName = $namePrefix + "rg"
$Location = "EASTUS"
$StorageAccountName = $namePrefix + "sa"

### Login to Azure       (Note:  You will be prompted to use a web browser to enter an authentication code at https://aka.ms/devicelogin)
az login 		

