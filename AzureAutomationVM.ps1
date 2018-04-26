### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"
$AccountName = "azureautomationaccount"
$VMCLX = "55224vm1"
$PW = Write-Output 'Pa$$w0rdPa$$w0rd' | ConvertTo-SecureString -AsPlainText -Force     # Password for Administrator account
$AdminCred = New-Object System.Management.Automation.PSCredential("Adminz",$PW)        # Login credentials for Administrator account
$Location = "eastus"
$namePrefix = "zz" + (Get-Date -Format "HHmmss")     # Replace zz with your initials.  Date information is added in this example to help make the names unique
$ResourceGroupName = $namePrefix + "rg"
$StorageAccountName = $namePrefix + "sa"     # Must be lower case
$PublicIPName1 = "PublicIP1"

### Login to Azure
Login-AzureRmAccount
# Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription
# $Credentials = get-azurermautomationcredential -Resourcegroup $ResourceGroupname -AutomationAccountName $AccountName
# Login-AzureRmAccount -Credential $Credentials

### Create Resource Group, Storage Account & Storage Account Share
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_RAGRS

### Create Network
$Subnet10 = New-AzureRmVirtualNetworkSubnetConfig -Name "Subnet10" -AddressPrefix 192.168.10.0/24 
$VirtualNetwork1 = New-AzureRmVirtualNetwork -Name "VirtualNetwork1" -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix 192.168.0.0/16 -Subnet $Subnet10
$PublicIP1 = New-AzureRmPublicIpAddress -Name $PublicIPName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static  
$CLXNIC1 = New-AzureRmNetworkInterface -Name "CLXNIC1" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VirtualNetwork1.Subnets[0].Id -PublicIpAddressId $PublicIP1.Id 

### Create Windows 10 VM
$VM1 = New-AzureRmVMConfig -VMName $VMCLX -VMSize "Standard_DS2"
$VM1 = Set-AzureRmVMOperatingSystem -VM $VM1 -Windows -ComputerName $VMCLX -Credential $AdminCred -WinRMHttp -ProvisionVMAgent -EnableAutoUpdate
$VM1 = Set-AzureRmVMSourceImage -VM $VM1 -PublisherName "MicrosoftVisualStudio" -Offer "Windows" -Skus "Windows-10-N-x64" -Version "latest"
$VM1 = Add-AzureRMVMNetworkInterface -VM $VM1 -ID $CLXNIC1.Id
$VHDURI1 = (Get-azureRMstorageaccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).PrimaryEndPoints.Blob.ToString() + "vhdclx/VHDCLX1.vhd"
$VM1 = Set-AzureRmVMOSDisk -VM $VM1 -Name "VHDCLX1" -VHDURI $VHDURI1 -CreateOption FromImage
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM1 -Verbose
Start-AzureRMVM -Name $VMCLX -ResourceGroupName $ResourceGroupName
$PublicIPAddress1 = Get-AzureRmPublicIpAddress -Name $PublicIPName1 -ResourceGroupName $ResourceGroupName
Write-Output "The virtual machine has been created.  Login as Adminz by using Remote Desktop Connection to connect to its Public IP address.  The IP Address will be added to your trusted hosts list."
Write-Output "Public IP Address for $VMCLX is: " $PublicIPAddress1.IpAddress
set-item wsman:localhost\client\trustedhosts -value $PublicIPAddress1.Ipaddress -Concatenate -Force 

### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
