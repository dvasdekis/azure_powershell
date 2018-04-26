Subst F: C:\Users\ContainerAdministrator\Clouddrive
CD F:\Labfiles
$WorkFolder = "F:\Labfiles\"
New-SelfSignedCertificate -DnsName "www.contoso.com" -CertStoreLocation "Cert:\CurrentUser\My" -Type CodeSigning
$Cert=(Get-ChildItem Cert:\CurrentUser\My\ -CodeSigningCert)
Get-ChildItem $WorkFolder"*.ps1" | Set-AuthenticodeSignature -Certificate $Cert

