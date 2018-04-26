### Configure Automation
### Configure Objects & Variables
# Get-ComputerInfo | Select CSDNSHostName, CSUserName, CSWorkGroup, OSName
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                     # Change to match your Azure subscription ID
$WorkFolder = "C:\Labfiles\Lab3\" ; $TempFolder = "C:\Labfiles\" 
$RunbookFile = $TempFolder + "azureautomationvm.ps1"
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                             # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"
$ContainerName = $NamePrefix + "con"
$AccountName = $NamePrefix + "account"
$AccountURI = "http://" + $AccountName
$RunbookName = $NamePrefix + "runbook"
$Location = "EASTUS2"

### Record the start time to your log file
$LogFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $LogFileSuffix = ".txt" ; $StartTime = Get-Date 
"Configure Automation" > $TempFolder$LogFilePrefix$LogFileSuffix
"Start Time: " + $StartTime >> $TempFolder$LogFilePrefix$LogFileSuffix

### Login to Azure
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account and Container
$RG = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $ContainerName -Context $StorageAccountContext 

### Create Automation Account
New-AzureRMAutomationAccount -ResourceGroupName $ResourceGroupName -Location $Location -Name $AccountName 
$Password = ConvertTo-SecureString "Password123" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AccountName, $Password
New-AzureRMAutomationCredential -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -Name $AccountName -Value $Credential
$Account = Get-AzureRMAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AccountName

$Key = [system.guid]::newguid()
$App = New-AzureRMADApplication -DisplayName $AccountName -HomePage $AccountURI -IdentifierUris $AccountURI -Password $Key.GUID
$SP = New-AzureRMADServicePrincipal -ApplicationID $App.ApplicationID #
Start-Sleep 60
New-AzureRMRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $App.ApplicationID.GUID

### Create Runbook
Import-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -Path $RunbookFile -Name $RunbookName -Type PowerShell -LogVerbose $True -LogProgress $True
Publish-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountname $Accountname -Name $RunbookName
Start-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountname $Accountname -Name $RunbookName

### Delete Resources and record the end time to your log file
$EndTime = Get-Date ; $et = $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$LogFilePrefix$logFileSuffix 
Rename-Item -Path $TempFolder$LogFilePrefix$LogFileSuffix -NewName $TempFolder"Time"$et$LogFileSuffix
### Remove-AzureRMResourceGroup -Name $ResourceGroupName -Verbose -Force
### Remove-AzureRMAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -Name $RunbookName -Force

