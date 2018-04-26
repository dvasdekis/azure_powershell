#$Key = [system.guid]::newguid()
$Password = ConvertTo-SecureString "Password321" -AsPlainText -Force
$AccountName = "ServicePrincipal1"
$AccountURI = "http://serviceprincipal1"
$App = New-AzureRMADApplication -DisplayName $AccountName -HomePage $AccountURI -IdentifierUris $AccountURI -Password $Password
$SP = New-AzureRMADServicePrincipal -ApplicationID $App.ApplicationID 
Start-Sleep 60
New-AzureRMRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $App.ApplicationID.GUID


