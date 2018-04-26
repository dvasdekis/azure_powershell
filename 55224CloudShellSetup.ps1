### Copy Labfiles to Azure Cloud Drive.  Facilitates use of Azure Cloud Shell in future labs.
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "Azure Subscription"                         # Replace with the name of your Azure Subscription
$CSResourceGroupName = "Cloud-Shell-Storage-EastUS"          # Replace with the name of your Azure Cloud Shell Resource Group
CD C:\Labfiles
$WorkFolder = "C:\Labfiles\"
$AzureDrive = "S"                                            # Temporary Drive assigned to Azure Cloud Drive
$AzureFolder = $AzureDrive + ":\Labfiles\"
$AzureTemp = $AzureDrive + ":\Temp\"
$Labfiles = "Labfiles"
$Temp = "Temp"

### Log start time of script
$logFilePrefix = "55224CloudShellSetup" + (Get-Date -Format "HHmm") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Configure Azure Cloud Shell Drive (55224A)"   >  $WorkFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $WorkFolder$logFilePrefix$logFileSuffix

### Login to Azure & Select Azure Subscription
Login-AzureRmAccount
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Get Clouddrive Properties based on the name of its Resource Group
$ResourceGroupName = $CSResourceGroupName
$Location = (Get-AzureRMResourceGroup -ResourceGroupName $ResourceGroupName).Location
$StorageAccountName = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName).StorageAccountName  
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
$FileShare = Get-AzureStorageShare -Context $StorageAccountContext

### Copy Labfiles Archive to Clouddrive and expand it
New-AzureStorageDirectory -ShareName $FileShare.Name -Path $Labfiles -Context $StorageAccountContext -Verbose -ErrorAction SilentlyContinue
$AS = New-AzureStorageShare $Labfiles -Context $StorageAccountContext
$FileShareURI = "\\" + $FileShare.Uri.Authority + "\" + $FileShare.Name
$acctName = "Azure\" + $StorageAccountName
$acctKey = ConvertTo-SecureString -String $StorageAccountKey -AsPlainText -Force
$PSDCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $acctName, $acctKey
Net Use $AzureDrive":" /delete
Get-PSDrive -Name $AzureDrive | Remove-PSDrive -Force
New-PSDrive -Name $AzureDrive -PSProvider FileSystem -Root $FileShareUri -Credential $PSDCredential -Persist
New-Item -Path $AzureFolder -ItemType Directory -Verbose -ErrorAction SilentlyContinue 
New-Item -Path $AzureTemp -ItemType Directory -Verbose -ErrorAction SilentlyContinue
Copy-Item $WorkFolder"55224A-ENU_PowerShellSetup.zip" -Destination $AzureFolder -Verbose -Force
Expand-Archive -LiteralPath $AzureFolder"55224A-ENU_PowerShellSetup.zip" -DestinationPath $AzureFolder -Verbose -Force
Expand-Archive -LiteralPath $AzureFolder"55224AzureSetup.zip" -DestinationPath $AzureFolder -Verbose -Force

### Log Azure Clouddrive Information
"Resource Group Name     :  " + $ResourceGroupName >> $WorkFolder$logFilePrefix$logFileSuffix
"Location                :  " + $Location >> $WorkFolder$logFilePrefix$logFileSuffix
"Storage Account Name    :  " + $StorageAccountName >> $WorkFolder$logFilePrefix$logFileSuffix
"File Share Name         :  " + $FileShare.Name >> $WorkFolder$logFilePrefix$logFileSuffix
$EndTime = Get-Date ; $et = "55224AzureSetup" + $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $WorkFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $WorkFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $WorkFolder$logFilePrefix$logFileSuffix -NewName $et$logFileSuffix
pip install --user --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
