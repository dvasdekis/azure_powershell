New-Item -Path C:\CustomScriptExtension, C:\Labfiles, C:\Temp -Type Directory -Force
Net LocalGroup "Remote Management Users" /Add Adminz
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
Get-NetFirewallRule *WINRM* | Set-NetFirewallRule -Profile Any -RemoteAddress Any
Get-NetFirewallRule *RemoteDesktop* | Set-NetFirewallRule -Profile Any -RemoteAddress Any
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
Enable-PSRemoting -Force
Set-WSManQuickConfig -Force
Restart-Computer

