### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "Azure Subscription"
$VMDC = "nyc-dc1"
$VMCLX = "student10"
$workFolder = "C:\Labfiles\" 
$azcopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy" 
$PW = ConvertTo-SecureString -AsPlainText 'Pa$$w0rdPa$$w0rd' -Force
$AdminCred = New-Object System.Management.Automation.PSCredential("Adminz",$PW)
$Location = "EASTUS"
$namePrefix = "aa" + (Get-Date -Format "HHmm")     # Replace "aa" with your initials
$ResourceGroupName = $namePrefix + "rg"
$StorageAccountName = $namePrefix + "sa"   # Must be lower case
$SAShare = "55224"   # Must be lower case
$PublicIPName1 = "PublicIP1"
$PUblicIPName2 = "PublicIP2"

### Log start time of script
$TempFolder = "C:\Labfiles\"
$LogFilePrefix = "Time" + (Get-Date -Format "HHmm") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Create Azure VM (55224)"   >  $TempFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $TempFolder$LogFilePrefix$LogFileSuffix

### Login to Azure
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account & Storage Account Share
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $location -Type Standard_RAGRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
New-AzureStorageContainer -Name $SAShare.ToLower() -Context $StorageAccountContext -Permission Container -Verbose 
$azcopycmd = "cmd.exe /C '$azcopyPath\azcopy.exe' /S /Y /NC:2 /Source:'$WorkFolder' /Dest:'https://$StorageAccountName.blob.core.windows.net/$SAShare' /DestKey:$StorageAccountKey /Pattern:55224setup.zip "
Invoke-Expression -Command:$azcopycmd

### Create Network
$Subnet10 = New-AzureRmVirtualNetworkSubnetConfig -Name "Subnet10" -AddressPrefix 192.168.10.0/24
$Subnet20 = New-AzureRmVirtualNetworkSubnetConfig -Name "Subnet20" -AddressPrefix 192.168.20.0/24 
$VirtualNetwork1 = New-AzureRmVirtualNetwork -Name "VirtualNetwork1" -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix 192.168.0.0/16 -Subnet $Subnet10, $Subnet20
$PublicIP1 = New-AzureRmPublicIpAddress -Name $PublicIPName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic  
$PublicIP2 = New-AzureRmPublicIpAddress -Name $PublicIPName2 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic 
$DCNIC1 = New-AzureRmNetworkInterface -Name "DCNIC1" -ResourceGroupName $ResourceGroupName -Location $Location -PrivateIPAddress 192.168.10.100 -SubnetId $VirtualNetwork1.Subnets[0].Id -PublicIpAddressId $PublicIP1.Id
$DCNIC2 = New-AzureRmNetworkInterface -Name "DCNIC2" -ResourceGroupName $ResourceGroupName -Location $Location -PrivateIPAddress 192.168.20.100 -SubnetId $VirtualNetwork1.Subnets[1].Id  
$CLXNIC1 = New-AzureRmNetworkInterface -Name "CLXNIC1" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VirtualNetwork1.Subnets[0].Id -PublicIpAddressId $PublicIP2.Id -DNSServer 192.168.10.100
$CLXNIC2 = New-AzureRmNetworkInterface -Name "CLXNIC2" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VirtualNetwork1.Subnets[1].Id  

### Create VMs
#Domain Controller
$VM1 = New-AzureRmVMConfig -VMName $VMDC -VMSize "Standard_DS2"
$VM1 = Set-AzureRmVMOperatingSystem -VM $VM1 -Windows -ComputerName $VMDC -Credential $AdminCred -WinRMHttp -ProvisionVMAgent -EnableAutoUpdate
$VM1 = Set-AzureRmVMSourceImage -VM $VM1 -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" -Version "latest"
$VM1 = Add-AzureRMVMNetworkInterface -VM $VM1 -ID $DCNIC1.Id -Primary
$VM1 = Add-AzureRMVMNetworkInterface -VM $VM1 -ID $DCNIC2.Id 
$VHDURI1 = (Get-azureRMstorageaccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).PrimaryEndPoints.Blob.ToString() + "vhddc/VHDDC1.vhd"
$VM1 = Set-AzureRmVMOSDisk -VM $VM1 -Name "VHDDC1" -VHDURI $VHDURI1 -CreateOption FromImage
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM1 -Verbose
Start-AzureRMVM -Name $VMDC -ResourceGroupName $ResourceGroupName
$PublicIPAddress1 = Get-AzureRmPublicIpAddress -Name $PublicIPName1 -ResourceGroupName $ResourceGroupName
Write-Output  "Public IP Address for $VMDC is: " $PublicIPAddress1.IpAddress
set-item wsman:localhost\client\trustedhosts -value $PublicIPAddress1.Ipaddress -Concatenate -Force 
Write-Output "`$Source` = `"https://$StorageAccountName.blob.core.windows.net/$SAShare/55224setup.zip`"" > $workFolder"configureazurevm.txt"
Get-Content $workFolder"configureAzureVM.txt" , $workFolder"configureAzureVM.ps0" | Set-Content $workFolder"configureAzureVM.ps1"
invoke-command -Computername $PublicIPAddress1.IpAddress -credential $AdminCred -File $workFolder"configureAzureVM.ps1" -AsJob -JobName $VMDC$NamePrefix

#Windows 10 Client
$PublisherName = "MicrosoftWindowsDesktop"
$Offer = (Get-AzureRMVMImageOffer -Location $Location -PublisherName $PublisherName)[1].Offer 
$Skus = (Get-AzureRmVMImagesku -Location $Location -PublisherName $PublisherName -Offer $Offer)[1].Skus
$VMSize = (Get-AzureRMVMSize -Location $Location | Where-Object {$_.Name -like "Standard_DS2*"})[0].Name
$VM2 = New-AzureRmVMConfig -VMName $VMCLX -VMSize $VMSize
$VM2 = Set-AzureRmVMOperatingSystem -VM $VM2 -Windows -ComputerName $VMCLX -Credential $AdminCred -WinRMHttp -ProvisionVMAgent -EnableAutoUpdate
$VM2 = Set-AzureRmVMSourceImage -VM $VM2 -PublisherName $PublisherName -Offer $Offer -Skus $Skus -Version "latest"
$VM2 = Add-AzureRMVMNetworkInterface -VM $VM2 -ID $CLXNIC1.Id -Primary
$VM2 = Add-AzureRMVMNetworkInterface -VM $VM2 -ID $CLXNIC2.Id
$VHDURI2 = (Get-azureRMstorageaccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).PrimaryEndPoints.Blob.ToString() + "vhdclx/VHDCLX1.vhd"
$VM2 = Set-AzureRmVMOSDisk -VM $VM2 -Name "VHDCLX1" -VHDURI $VHDURI2 -CreateOption FromImage
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM2 -Verbose
Start-AzureRMVM -Name $VMCLX -ResourceGroupName $ResourceGroupName
$PublicIPAddress2 = Get-AzureRmPublicIpAddress -Name $PublicIPName2 -ResourceGroupName $ResourceGroupName
Write-Output  "Public IP Address for $VMCLX is: " $PublicIPAddress2.IpAddress
set-item wsman:localhost\client\trustedhosts -value $PublicIPAddress2.Ipaddress -Concatenate -Force 
invoke-command -Computername $PublicIPAddress2.IpAddress -credential $AdminCred -File $workFolder"configureAzureVM.ps1" -AsJob -JobName $VMCLX$NamePrefix

### Delete Resources and log end time of script
### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
"PublicIP1:  " + $PublicIPAddress1.IpAddress >> $TempFolder$LogFilePrefix$LogFileSuffix
"PublicIP2:  " + $PublicIPAddress2.IpAddress >> $TempFolder$LogFilePrefix$LogFileSuffix
$EndTime = Get-Date ; $et = "Time" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $tempFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$LogFilePrefix$LogFileSuffix 
Rename-Item -Path $TempFolder$LogFilePrefix$LogFileSuffix -NewName $et$LogFileSuffix
# Remove-Item -Path $workFolder -Force -Recurse -ErrorAction "Continue"

