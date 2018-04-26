### Configure Objects & Variables
# Install-Module -Name AzureAD -Force                                      # Only needs to be run once
# Install-Module -Name MSOnline -Force                                     # Only needs to be run once
Import-Module AzureAD
Import-Module MSOnline
Set-StrictMode -Version 2.0
$SubscriptionID = "MSDN Platforms"
$workFolder = "C:\Labfiles\Lab3\" ; $TempFolder = "C:\Labfiles\" 
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                    # Replace "in" with your initials
$DomainName = "neiltucker.tk"                                                   # Replace with the domain name you want to register
$UPN = $NamePrefix + "@" + $DomainName
$ResourceGroupName = $NamePrefix + "rg"
$Location = "NORTHEUROPE"

### Log start time of script
$logFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Configure Azure AD" > $tempFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $tempFolder$logFilePrefix$logFileSuffix

### Connect to Azure
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionID | Select-AzureRmSubscription
Connect-MSOLService

### New MSOL Domain and User
# New-MSOLDomain -Name $DomainName
# $DV = Get-MSOLDomainVerificationDNS -DomainName $DomainName -Mode DNSTxtRecord
# Confirm-MSOLDomain -DomainName $DomainName
# Set-MSOLDomain -Name $DomainName -IsDefault
# New-MSOLUser -UserPrincipalName $UPN -DisplayName $NamePrefix
# Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberEmailAddress $UPN
# Get-MSOLUser



<# 
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = "Password123"
New-AzureADUser -UserPrincipalName $UPN -DisplayName $NamePrefix -MailNickName $NamePrefix -PasswordProfile $PasswordProfile -AccountEnabled $True 

=======

$ADUserParams = @{ 
 UserPrincipalName = $UPN 
 DisplayName = "User1" 
 MailNickname = "User1" 
 Password = "Password123"
} 
New-AzureRMADUser @ADUserParams 
#>