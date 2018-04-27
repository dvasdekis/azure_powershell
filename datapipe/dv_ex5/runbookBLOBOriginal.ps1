### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionID = "<subscriptionid>"
$TenantID = "<tenantid>"
$ApplicationID = "<applicationid>"
$CertificateThumbprint = "<certificatethumbprint>"
$RemoteNamePrefix = "<remotenameprefix>"
$RemoteResourceGroupName = $RemoteNamePrefix + "rg"
$RemoteContainerName = $RemoteNamePrefix + "stor"
$RemoteStorageAccountName = $RemoteNamePrefix + "sa"
$RemoteBlob = "https://" + $RemoteStorageAccountName + ".blob.core.windows.net/" + $RemoteContainerName
$WorkFolder = "C:\Labfiles\Lab3\" ; New-Item -ItemType "Directory" -Path $WorkFolder -Force
$Location = "EASTUS"
$NamePrefix = ("run" + (Get-Date -Format "HHmmss")).ToLower()                            
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"     # Must be lower case
$ContainerName = $NamePrefix + "stor"

### Login to Azure
Login-AzureRmAccount -ServicePrincipal -TenantId $TenantID -ApplicationID $ApplicationID -CertificateThumbprint $CertificateThumbprint
Select-AzureRMSubscription -SubscriptionID $SubscriptionID -TenantID $TenantID

### Configure Remote Container Connection
$RemoteStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RemoteResourceGroupName -Name $RemoteStorageAccountName)[0].Key1
$RemoteStorageAccountContext = New-AzureStorageContext -StorageAccountName $RemoteStorageAccountName -StorageAccountKey $RemoteStorageAccountKey 

### Create Resource Group, Storage Account & Storage Account Share
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Key1
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $ContainerName -Context $StorageAccountContext -Permission Container 

### Copy from remote BLOB and from local file system
Get-AzureStorageBlob -Container $RemoteContainerName -Context $RemoteStorageAccountContext | Get-AzureStorageBlobContent -Destination $WorkFolder -Force
ls -File $WorkFolder -Recurse | Set-AzureStorageBlobContent -Container $ContainerName -Context $StorageAccountContext -Force

### Start-Sleep -Seconds 600 | Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
