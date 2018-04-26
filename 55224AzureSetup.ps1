### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                     # Replace with the name of your Azure Subscription
$WorkFolder = "C:\Labfiles\"
$PW = Write-Output 'Pa$$w0rdPa$$w0rd' | ConvertTo-SecureString -AsPlainText -Force     # Password for Administrator account
$AdminCred = New-Object System.Management.Automation.PSCredential("Adminz",$PW)        # Login credentials for Administrator account
$Location = "EASTUS"
$VMCLX = "VM55224A"                               
$NamePrefix = "IN" + (Get-Date -Format "HHmmss")       # Replace "IN" with your initials.  Date information is added in this example to help make the names unique
$ResourceGroupName = $NamePrefix.ToLower() + "rg"
$StorageAccountName = $NamePrefix.ToLower() + "sa"     # Must be lower case
$SAShare = "55224a"                                    # Must be lower case
$PublicIPName1 = "PublicIP1"

### Log start time of script
$logFilePrefix = "55224AzureSetup" + (Get-Date -Format "HHmm") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Create Azure VM (55224A)"   >  $WorkFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $WorkFolder$logFilePrefix$logFileSuffix

### Login to Azure
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account & Storage Account Share
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_RAGRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
New-AzureStorageContainer -Name $SAShare.ToLower() -Context $StorageAccountContext -Permission Container -Verbose 
Get-ChildItem $WorkFolder"55224CustomScriptExtension.ps1" -Recurse | Set-AzureStorageBlobContent -Container $SAShare -Context $StorageAccountContext -Force

### Create Network
$Subnet10 = New-AzureRmVirtualNetworkSubnetConfig -Name "Subnet10" -AddressPrefix 192.168.10.0/24 
$VirtualNetwork1 = New-AzureRmVirtualNetwork -Name "VirtualNetwork1" -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix 192.168.0.0/16 -Subnet $Subnet10
$PublicIP1 = New-AzureRmPublicIpAddress -Name $PublicIPName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic  
$CLXNIC1 = New-AzureRmNetworkInterface -Name "CLXNIC1" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VirtualNetwork1.Subnets[0].Id -PublicIpAddressId $PublicIP1.Id 
# $NSGWinRMRule = New-AzureRMNetworkSecurityRuleConfig -Name WinRMRule -Description "WinRM Rule" -Access Allow -Protocol * -Direction Inbound -Priority 101 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5985,5986
# $NSGRDPRule = New-AzureRMNetworkSecurityRuleConfig -Name RDPRule -Description "RDP Rule" -Access Allow -Protocol * -Direction Inbound -Priority 102 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389,3390
# $NSG1 = New-AzureRMNetworkSecurityGroup -Name "NSG1" -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $NSGWinRMRule,$NSGRDPRule -Force
# $CLXNIC1.NetworkSecurityGroup = $NSG1
# $CLXNIC1 | Set-AzureRMNetworkInterface

### Create Windows 10 VM
# Get-AzureRMVMImagePublisher -Location $Location | Where-Object { $_.PublisherName -like "Microsoft*" }
$PublisherName = "MicrosoftWindowsDesktop"
$Offer = (Get-AzureRMVMImageOffer -Location $Location -PublisherName $PublisherName)[1].Offer 
$Skus = (Get-AzureRmVMImagesku -Location $Location -PublisherName $PublisherName -Offer $Offer)[1].Skus
$VMSize = (Get-AzureRMVMSize -Location $Location | Where-Object {$_.Name -like "Standard_DS2*"})[0].Name
$VM1 = New-AzureRmVMConfig -VMName $VMCLX -VMSize $VMSize 
$VM1 = Set-AzureRmVMOperatingSystem -VM $VM1 -Windows -ComputerName $VMCLX -Credential $AdminCred -WinRMHttp -ProvisionVMAgent -EnableAutoUpdate
$VM1 = Set-AzureRmVMSourceImage -VM $VM1 -PublisherName $PublisherName -Offer $Offer -Skus $Skus -Version "latest"
$VM1 = Add-AzureRMVMNetworkInterface -VM $VM1 -ID $CLXNIC1.Id
$VHDURI1 = (Get-AzureRMStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).PrimaryEndPoints.Blob.ToString() + "vhdclx/VHDCLX1.vhd"
$VM1 = Set-AzureRmVMOSDisk -VM $VM1 -Name "VHDCLX1" -VHDURI $VHDURI1 -CreateOption FromImage
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM1 -Verbose
Start-AzureRMVM -Name $VMCLX -ResourceGroupName $ResourceGroupName 
# $VMAA = Get-AzureRmVMExtensionImage -PublisherName "Microsoft.Compute" -Type "VMAccessAgent" -Location $Location
# $Settings = @{"fileUris" = ""; "commandToExecute" = "55224CustomScriptExtension.ps1"}
# $ProtectedSettings = @{"storageAccountName" = $StorageAccountName ; "storageAccountKey" = $StorageAccountKey }
# Set-AzureRMVMExtension -ResourceGroupName $ResourceGroupName -Location $Location -VMName $VMCLX -Name $VMAA[0].Type -Publisher $VMAA[0].PublisherName -Type $VMAA[0].Type -TypeHandlerVersion $VMAA[0].Version -Settings $Settings -ProtectedSettings $ProtectedSettings
$VMCSE = Get-AzureRmVMExtensionImage -PublisherName "Microsoft.Compute" -Type "CustomScriptExtension" -Location $Location
Set-AzureRmVMCustomScriptExtension -Name $VMCSE[-1].PublisherName -TypeHandlerVersion $VMCSE[-1].Version -FileName "55224CustomScriptExtension.ps1" -Run "55224CustomScriptExtension.ps1" -ForceRerun $(New-Guid).Guid -ContainerName $SAShare -ResourceGroupName $ResourceGroupName -VMName $VMCLX -Location $Location -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
$PublicIPAddress1 = Get-AzureRmPublicIpAddress -Name $PublicIPName1 -ResourceGroupName $ResourceGroupName
Write-Output "The virtual machine has been created.  Login as Adminz by using Remote Desktop Connection to connect to its Public IP address.  The IP Address will be added to your trusted hosts list."
Write-Output "Public IP Address for $VMCLX is: " $PublicIPAddress1.IPAddress
Set-Item wsman:localhost\client\trustedhosts -value $PublicIPAddress1.IPAddress -Concatenate -Force 
$AdminUser=$PublicIPAddress1.IPAddress + "`\Adminz"
$AdminCred2 = New-Object System.Management.Automation.PSCredential($AdminUser,$PW)        # Login credentials for Administrator account
# Enter-AzureRmVm -Name $VMCLX -ResourceGroup $ResourceGroupName -Credential $AdminCred2 -EnableRemoting
# Invoke-AzureRmVMCommand -Name $VMCLX -ResourceGroupName $ResourceGroupName -Scriptblock {New-Item C:\InvokeAzureRMVMCommand -Type Directory -Force} -Credential $AdminCred2
$PSSession = New-PSSession -ComputerName $PublicIPAddress1.IPAddress -Credential $AdminCred2
Copy-Item -ToSession $PSSession -Path $WorkFolder"55224A-ENU_PowerShellSetup.zip" -Destination "C:\Labfiles\" -Recurse -Force -ErrorAction Continue
Copy-Item -ToSession $PSSession -Path $WorkFolder"55224ConfigAZVM.ps1" -Destination "C:\Labfiles\" -Recurse -Force -ErrorAction Continue
Invoke-Command -ComputerName $PublicIPAddress1.IPAddress -Credential $AdminCred2 -ScriptBlock {Expand-Archive -LiteralPath "C:\Labfiles\55224A-ENU_PowerShellSetup.zip" -DestinationPath "C:\Labfiles" -Force} 
Invoke-Command -ComputerName $PublicIPAddress1.IPAddress -Credential $AdminCred2 -ScriptBlock {C:\Labfiles\55224ConfigAZVM.ps1}
Remove-PSSession $PSSession

### Log VM Information and delete the Resource Group
"Student PC   Internet IP:  " + $PublicIPAddress1.IpAddress >> $WorkFolder$logFilePrefix$logFileSuffix
"Resource Group Name     :  " + $ResourceGroupName + "   # Delete the Resource Group to remove all Azure resources created by this script (e.g. Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force)"  >> $WorkFolder$logFilePrefix$logFileSuffix
$EndTime = Get-Date ; $et = "55224AzureSetup" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $WorkFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $WorkFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $WorkFolder$logFilePrefix$logFileSuffix -NewName $et$logFileSuffix
pip install --user --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure-mgmt-resource, azure-mgmt-datafactory
### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
