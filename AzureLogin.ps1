### Login
$SubscriptionID = "MSDN Platforms"                                                       # Change to match your Azure subscription ID
$namePrefix = "IN"                                                                       # Change the name prefix to use your initials 
$namePrefix = $namePrefix.ToLower() + (Get-Date -Format "HHmmss")
$ResourceGroupName = $namePrefix + "rg"
$Location = "EASTUS"

### Login to Azure
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $SubscriptionID | Select-AzureRmSubscription
