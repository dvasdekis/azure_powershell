### Process an interactive job using HDInsight (Spark)
### Configure Objects & Variables
Set-StrictMode -Version 2.0
$SubscriptionName = "MSDN Platforms"                                                     # Change to match your Azure subscription ID
$ExternalIP = ((Invoke-WebRequest http://icanhazip.com -UseBasicParsing).Content).Trim()          # "nslookup myip.opendns.com resolver1.opendns.com" or http://whatismyip.com will also get your Public IP
$ExternalIPNew = [Regex]::Replace($ExternalIP, '\d{1,3}$', {[Int]$args[0].Value + 1})
$namePrefix = "aa"                                                                       # Change the name prefix to use your initials 
$WorkFolder = "C:\Labfiles\Lab1\" ; $StatusFolder = "C:\Labfiles\" ; New-Item -Path $WorkFolder, $StatusFolder -ItemType Directory -Force -ErrorAction "SilentlyContinue"
$namePrefix = $namePrefix.ToLower() + (Get-Date -Format "HHmmss")
$resourceGroupName = $namePrefix + "rg"
$Location = "EASTUS"
$HDInsightClusterName = $namePrefix + "hdi"
$AdminName="clusteradmin"
$AdminPassword="P@ssword123"
$SSHName = "sshadmin"
$SSHPassword = "P@assword123"
$StorageAccountName = $namePrefix + "sa"
$BlobContainerName = $HDInsightClusterName 

### Record the start time to your log file
$logFilePrefix = "Time" + (Get-Date -Format "HHmmss") ; $logFileSuffix = ".txt" ; $StartTime = Get-Date 
"Azure Interactive Processing" > $StatusFolder$logFilePrefix$logFileSuffix
"Start Time: " + $StartTime >> $StatusFolder$logFilePrefix$logFileSuffix

### Login to Azure
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

### Create Resource Group, Storage Account and Blob
New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -Location $Location -Type Standard_LRS
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
New-AzureStorageContainer -Name $BlobContainerName -Context $StorageAccountContext 

### Copy local files to Azure Blob
Get-Childitem $WorkFolder"*.csv" | Set-AzureStorageBlobContent -Container $BlobContainerName -Context $StorageAccountContext -Force

### Configure Cluster Resources
$PW=ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$clusterCredential=New-Object System.Management.Automation.PSCredential ($AdminName, $PW)
$SSHPW=ConvertTo-SecureString $SSHPassword -AsPlainText -Force
$ClusterSSHCredential=New-Object System.Management.Automation.PSCredential ($SSHName, $SSHPW)
$AzureHDInsightConfigs= New-AzureRmHDInsightClusterConfig -ClusterType Spark
$AzureHDInsightConfigs.DefaultStorageAccountKey = $StorageAccountKey
$AzureHDInsightConfigs.DefaultStorageAccountName = "$StorageAccountName.blob.core.windows.net"

### Create Cluster and Install Zeppelin
Add-AzureRMHDInsightScriptAction -Config $azureHDInsightConfigs -Name "Install Zeppelin" -NodeType HeadNode -Parameters "void" `
                                 -Uri "https://hdiconfigactions.blob.core.windows.net/linuxincubatorzeppelinv01/install-zeppelin-spark160-v01.sh"

New-AzureRMHDInsightCluster -Config $AzureHDInsightConfigs -OSType Linux -HeadNodeSize "Standard_D12" `
                            -WorkerNodeSize "Standard_D12" -ClusterSizeInNodes 2 -Location $Location `
                            -ResourceGroupName $resourceGroupName -ClusterName $HDInsightClusterName `
                            -HttpCredential $ClusterCredential -DefaultStorageContainer $BlobContainerName `
                            -SshCredential $ClusterSSHCredential -Version "3.5"

<# Snippet for Zeppelin Notebook (https://$hdinsightclustername.azurehdinsight.net/zeppelin)
%livy.spark
 // Create Resilient Distributed DataSet from csv
 val HRCSV = sc.textFile("wasbs:///hospitalreadmissions.csv")

 // Query the first 10 records in the RDD
 hrcsv take(10) foreach println

 // Define a schema
 case class record(hospitalname:String, providernumber:String, state:String, measurename:String, numberofdischarges:String, footnote:String, excessreadmissionratio:String, predictedreadmissionrate:String, expectedreadmissionrate:String, numberofreadmissions:String, startdate:String, enddate:String)

 // Map the csv to the schema
 val HRTable = HRCSV.map(s => s.split(",") ).map(
    s => record(s(0), 
                s(1),
                s(2),
                s(3), 
                s(4), 
                s(5),
                s(6), 
                s(7),            
                s(8),
                s(9),
                s(10),
                s(11)
        )
).toDF()


 // Register HRTable as a temporary table
 HRTable.registerTempTable("HRTable")

// Query HRTable
%sql
 select state,sum(numberofdischarges) as discharges from HRTable 
 where numberofdischarges > 0
 group by state
 order by discharges desc

 //  Convert RDD to DataFrame
 val hrcsvDF = hrcsv.toDF()

  // Write to and read from Parquet File
 hrcsvDF.write.parquet("hr.parquet")  
 val HRparquetDF = sqlContext.read.parquet("hr.parquet") 
 HRparquetDF.show()
 #>


### Delete Cluster and the end time to your log file
Remove-AzureRMResourceGroup -Name $resourceGroupName -Force
$EndTime = Get-Date ; $et = $EndTime.ToString("yyyyMMddHHmm")
"End Time:   " + $EndTime >> $StatusFolder$logFilePrefix$logFileSuffix
"Duration:   " + ($EndTime - $StartTime).TotalMinutes + " (Minutes)" >> $StatusFolder$logFilePrefix$logFileSuffix 
Rename-Item -Path $StatusFolder$logFilePrefix$logFileSuffix -NewName $StatusFolder"Time"$et$logFileSuffix
