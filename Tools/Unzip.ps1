# Unzip Setup Files
$Archive = "C:\Classfiles\55224azuresetup.zip"
$LabFolder = "C:\Classfiles\"
$LabCmd = "C:\Classfiles\run.cmd"
$File = New-Object -Com Shell.Application
$Zip = $File.Namespace($Archive)
$Unzip = 'ForEach ($Item in $Zip.Items()) {$File.Namespace($LabFolder).CopyHere($Item)}'
If (![System.IO.File]::Exists($LabCmd)) {Invoke-Expression $Unzip}
