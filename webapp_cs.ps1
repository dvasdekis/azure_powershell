### Create Web App
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                                   # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
Set-Location F:\Labfiles
$WorkFolder = "F:\Labfiles\" ; $TempFolder = "F:\Temp\" 
$Location = "EASTUS"
$NamePrefix = "web" + (Get-Date -Format "HHmmss")                         # Replace "web" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix.ToLower() + "sa"                       # Must be lower case
$AzureShareName = "labfiles"
$ServicePlanName = $NamePrefix + "spn"
$WebAppName = $NamePrefix + "app"
$GRPath = "https://github.com/Azure-Samples/app-service-web-html-get-started.git"

### Login to Azure
# Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account & Azure Share
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $location -Type Standard_RAGRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
$StorageShare = New-AzureStorageShare $AzureShareName -Context $StorageAccountContext

### Create Service Plan and Web App
$SP = New-AzureRMAppServicePlan -ResourceGroupName $ResourceGroupName -Name $ServicePlanName -Location $Location -Tier "Free" 
New-AzWebApp -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -AppServicePlan $ServicePlanName -GitRepositoryPath $GRPath -Auto

### Copy local file to Azure Share and verify
New-AzureStorageDirectory -Share $StorageShare -Path txtfiles
Get-ChildItem $WorkFolder"*.txt" -Recurse | Set-AzureStorageFileContent -Share $StorageShare -Path /txtfiles -Force
Get-AzureStorageFile -Sharename $AzureShareName -Context $StorageAccountContext
 
### Copy Azure Share file to local directory and verify
Get-AzureStorageFileContent -Share $StorageShare -Path password.txt -Destination $TempFolder -Force
Get-ChildItem $TempFolder 

### Remove Resource Group and all objects associated with it
# Remove-AzureRMResourceGroup -Name $resourceGroupName -Force
