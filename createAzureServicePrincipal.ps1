### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"
$workFolder = "C:\Labfiles\Lab3\" ; $TempFolder = "C:\Labfiles\" 
$NamePrefix = ("sp" + (Get-Date -Format "HHmmss")).ToLower()                    # Replace "sp" with your initials
$AppName = $NamePrefix
$AppURI = "http://" + $AppName

### Log start time of script
$logFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Create Azure Service Principal" > $tempFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $tempFolder$logFilePrefix$logFileSuffix

### Login to Azure
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Azure Service Principal 
$Key = [system.guid]::newguid()
$KeyCredentials = New-Object Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential
$KeyCredentials.KeyID = $key
$App = New-AzureRMADApplication -DisplayName $AppName -HomePage $AppURI -IdentifierUris $AppURI -Password $Key.GUID
$SP = New-AzureRMADServicePrincipal -ApplicationID $App.ApplicationID -KeyCredentials $KeyCredentials
Start-Sleep 60
New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $App.ApplicationID.GUID

### Delete Resources and log end time of script
$EndTime = Get-Date ; $et = $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $TempFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $TempFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $TempFolder$logFilePrefix$logFileSuffix -NewName $TempFolder"Time"$et$logFileSuffix
# Sleep 900 ; Remove-AzureRMResourceGroup -Name $ResourceGroupName -Force
