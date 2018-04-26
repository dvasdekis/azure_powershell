New-Item -Path C:\Labfiles -Type Directory -Force
New-Item -Path C:\Temp -Type Directory -Force
New-Item -Path C:\ConfigAZVM -Type Directory -Force
$SetupFile = "C:\Labfiles\55224AzureSetup.zip"
$LabfilesFolder = "C:\Labfiles"
Expand-Archive -LiteralPath $SetupFile -DestinationPath $LabfilesFolder -Force
Enable-NetFirewallRule -DisplayName "File and Printer Sharing*"
#   Get-DNSClient -InterfaceAlias Ethernet* | Set-DNSClient -ConnectionSpecificSuffix "contoso.com"
#   Get-DNSClient -InterfaceAlias Ethernet* | Set-DNSClientServerAddress -ServerAddresses ("192.168.10.100","192.168.20.100")
C:\Labfiles\run.cmd
