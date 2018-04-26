Login-AzureRmAccount
$SPName = "ServicePrincipal1"
$Password = "Pa$$w0rd123"
$SecurePassword = convertto-securestring $Password -asplaintext -force
$SP = New-AzureRmADServicePrincipal -DisplayName $SPName -Password $SecurePassword
Start-Sleep 60
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $SP.ApplicationId
# pip install --user --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure-mgmt-resource, azure-mgmt-datafactory

