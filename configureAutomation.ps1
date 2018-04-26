### Configure Automation
### Configure Objects & Variables
Import-Module -Name AzureRM.Resources
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                     # Change to match your Azure subscription ID
$WorkFolder = "C:\Labfiles\Lab3\" ; $TempFolder = "C:\Labfiles\" 
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$RunbookFileOriginal = $TempFolder + "runbookdatafactoryOriginal.ps1"
$RunbookFile = $TempFolder + "runbookdatafactory.ps1"
$RunbookName = "runbookdatafactory"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                             # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$AccountName = $NamePrefix + "account"
$AccountURI = "http://" + $AccountName
$Location = "EASTUS2"
$Password = "Password123"
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$CertFolder = "cert:\LocalMachine\My"
$PFXFile = $WorkFolder + $AccountName + ".pfx"
	
### Record the start time to your log file
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Configure Automation" > $TempFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $TempFolder$LogFilePrefix$LogFileSuffix

### Login to Azure
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group & Storage Account
New-AzureRmResourceGroup -Name $ResourceGroupName  -Location $Location

### Create and Install Certificate
Set-Location $CertFolder
$Certificate = New-SelfSignedCertificate -FriendlyName $AccountName -DNSName $AccountName -KeyExportPolicy "Exportable" -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -CertStoreLocation $CertFolder
Export-PfxCertificate -Cert $Certificate.Thumbprint -FilePath $PFXFile -Password $SecPassword
$Cert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate -ArgumentList @($PFXFile, $SecPassword)
$KeyHash = [System.Convert]::ToBase64String($Cert.GetRawCertData())
$Key = [guid]::NewGuid()
$KeyCredential = New-Object -TypeName Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential
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
Select-AzureRMSubscription -SubscriptionID $Subscription.Subscription.SubscriptionID -TenantID $Subscription.Tenant.TenantID

### Configure Automation Account Variables
$AutomationAccount = Get-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName 
New-AzureRmAutomationVariable -Name “SubscriptionID” -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -Value $Subscription.Subscription.SubscriptionID -Encrypted $False
New-AzureRmAutomationVariable -Name “TenantID” -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Value $Subscription.Tenant.TenantID -Encrypted $False
New-AzureRmAutomationVariable -Name “ApplicationID” -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AccountName -Value $App.ApplicationID.GUID -Encrypted $False
# New-AzureRmAutomationVariable -Name “NamePrefix” -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AccountName -Value $NamePrefix -Encrypted $False
New-AzureRmAutomationVariable -Name “CertificateThumbprint” -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AccountName -Value $Certificate.Thumbprint -Encrypted $False
# New-AzureRmAutomationVariable -Name “Location” -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AccountName -Value $Location -Encrypted $False
# New-AzureRmAutomationVariable -Name “StorageAccountKey” -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AccountName -Value $StorageAccountKey -Encrypted $False

### Create and Execute Runbook
Copy-Item $RunbookFileOriginal $RunbookFile -Force
(Get-Content $RunbookFile) -Replace '<subscriptionid>', $Subscription.Subscription.SubscriptionID | Set-Content $RunbookFile
(Get-Content $RunbookFile) -Replace '<tenantid>', $Subscription.Tenant.TenantID | Set-Content $RunbookFile
(Get-Content $RunbookFile) -Replace '<applicationid>', $App.ApplicationID.GUID | Set-Content $RunbookFile
# (Get-Content $RunbookFile) -Replace '<nameprefix>', $NamePrefix | Set-Content $RunbookFile
(Get-Content $RunbookFile) -Replace '<certificatethumbprint>', $Certificate.Thumbprint | Set-Content $RunbookFile
# (Get-Content $RunbookFile) -Replace '<location>', $Location | Set-Content $RunbookFile
# (Get-Content $RunbookFile) -Replace '<storageaccountkey>', $StorageAccountKey | Set-Content $RunbookFile
Import-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -Path $RunbookFile -Name $RunbookName -Type PowerShell -LogVerbose $True -LogProgress $True
Publish-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountname $Accountname -Name $RunbookName
Start-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountname $Accountname -Name $RunbookName

### Delete Resources and record the end time to your log file
$EndTime = Get-Date ; $et = $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$LogFilePrefix$logFileSuffix 
Rename-Item -Path $TempFolder$LogFilePrefix$LogFileSuffix -NewName $TempFolder"Time"$et$LogFileSuffix
# Login-AzureRmAccount -ServicePrincipal -TenantId $Subscription.Tenant.TenantID -ApplicationID $App.ApplicationID.GUID -CertificateThumbprint $Certificate.Thumbprint
# Select-AzureRMSubscription -SubscriptionID $Subscription.Subscription.SubscriptionID -TenantID $Subscription.Tenant.TenantID
### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force


