### Configure Automation
### Configure Objects & Variables
Import-Module -Name AzureRM.Resources
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                     # Change to match your Azure subscription ID
$WorkFolder = "C:\Labfiles\Lab3\" ; $TempFolder = "C:\Labfiles\" 
$RunbookFileOriginal = $TempFolder + "runbookBLOBOriginal.ps1"
$RunbookFile = $TempFolder + "runbookBLOB.ps1"
$RunbookName = "runbookBLOB"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                             # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"     # Must be lower case
$ContainerName = $NamePrefix + "stor"
$AccountName = $NamePrefix + "account"
$AccountURI = "http://" + $AccountName
$Location = "EASTUS2"
$Password = "Password123"
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$CertFolder = "cert:\LocalMachine\My"
$PFXFile = $WorkFolder + $AccountName + ".pfx"
	
### Record the start time to your log file
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Deploy Blob with a runbook" > $TempFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $TempFolder$LogFilePrefix$LogFileSuffix

### Login to Azure
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group & Storage Account
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $ContainerName -Context $StorageAccountContext -Permission Container 

### Copy local files to Azure Blob
Get-ChildItem $WorkFolder -Recurse | Set-AzureStorageBlobContent -Container $ContainerName -Context $StorageAccountContext -Force

### Create and Install Certificate
Set-Location $CertFolder
$Certificate = New-SelfSignedCertificate -FriendlyName $AccountName -DNSName $AccountName -KeyExportPolicy "Exportable" -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -CertStoreLocation $CertFolder
Export-PfxCertificate -Cert $Certificate.Thumbprint -FilePath $PFXFile -Password $SecPassword
$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Certificate)
$KeyHash = [System.Convert]::ToBase64String($Cert.GetRawCertData())
$Key = [guid]::NewGuid()
$KeyCredential = New-Object -TypeName Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADKeyCredential          
$KeyCredential.CertValue = $KeyHash
$KeyCredential.StartDate = Get-Date
$KeyCredential.EndDate = (Get-Date).AddYears(1)
Set-Location Cert:\currentuser\my
$CStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","CurrentUser")
$CStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$CStore.Add($Certificate)
$CStore.Close()
Set-Location $WorkFolder

### Configure Automation Account
$App = New-AzureRMADApplication -KeyCredentials $KeyCredential -DisplayName $AccountName -HomePage $AccountURI -IdentifierUris $AccountURI 
$SP = New-AzureRmADServicePrincipal -ApplicationID $App.ApplicationID
Start-Sleep 60
New-AzureRmRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $App.ApplicationID.GUID
New-AzureRMAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Location $Location
New-AzureRmAutomationCertificate -Name $AccountName -ResourceGroupName $ResourceGroupName -Path $PFXFile -Password $SecPassword -AutomationAccountName $AccountName 

### Login as Service Principal
Login-AzureRmAccount -CertificateThumbprint $Certificate.Thumbprint -TenantId $Subscription.Tenant.TenantID -ApplicationID $App.ApplicationID.GUID -ServicePrincipal
$SPSubscription = Select-AzureRMSubscription -SubscriptionID $Subscription.Subscription.SubscriptionID -TenantID $Subscription.Tenant.TenantID

### Configure Automation Account Variables
$AutomationAccount = Get-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName 
New-AzureRmAutomationVariable -Name “SubscriptionID” -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -Value $Subscription.Subscription.SubscriptionID -Encrypted $False
New-AzureRmAutomationVariable -Name “TenantID” -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Value $Subscription.Tenant.TenantID -Encrypted $False
New-AzureRmAutomationVariable -Name “ApplicationID” -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AccountName -Value $App.ApplicationID.GUID -Encrypted $False
New-AzureRmAutomationVariable -Name “CertificateThumbprint” -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AccountName -Value $Certificate.Thumbprint -Encrypted $False

### Create and Execute Runbook
Copy-Item $RunbookFileOriginal $RunbookFile -Force
(Get-Content $RunbookFile) -Replace '<subscriptionid>', $Subscription.Subscription.SubscriptionID | Set-Content $RunbookFile
(Get-Content $RunbookFile) -Replace '<tenantid>', $Subscription.Tenant.TenantID | Set-Content $RunbookFile
(Get-Content $RunbookFile) -Replace '<applicationid>', $App.ApplicationID.GUID | Set-Content $RunbookFile
(Get-Content $RunbookFile) -Replace '<certificatethumbprint>', $Certificate.Thumbprint | Set-Content $RunbookFile
(Get-Content $RunbookFile) -Replace '<remotenameprefix>', $NamePrefix | Set-Content $RunbookFile
Import-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -Path $RunbookFile -Name $RunbookName -Type PowerShell -LogVerbose $True -LogProgress $True
Start-Sleep 60
Publish-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountname $Accountname -Name $RunbookName
Start-Sleep 60
Start-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountname $Accountname -Name $RunbookName

<#
Verify that the runbook was created and that it ran successfully.  The resource group it creates will have a name prefix of "run".
If there are problems, wait five (5) minutes and try running it again from the script (Start-AzureRMAutomationRunbook) or from the Azure Portal.
#>

### Delete Resources and record the end time to your log file
$EndTime = Get-Date ; $et = $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$LogFilePrefix$logFileSuffix 
Rename-Item -Path $TempFolder$LogFilePrefix$LogFileSuffix -NewName $TempFolder"Time"$et$LogFileSuffix
# Login-AzureRmAccount -ServicePrincipal -TenantId $Subscription.Tenant.TenantID -ApplicationID $App.ApplicationID.GUID -CertificateThumbprint $Certificate.Thumbprint
# Select-AzureRMSubscription -SubscriptionID $Subscription.Subscription.SubscriptionID -TenantID $Subscription.Tenant.TenantID
### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
