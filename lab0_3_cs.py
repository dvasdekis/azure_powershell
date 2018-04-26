# Use this script in the Azure Cloud Shell.  Run the commands below in a PowerShell session then open a Python Shell to run the main body of the script.
# pip install --upgrade pandas, pandas_datareader, scipy, matplotlib, pyodbc, pycountry, azure
'''
$SubscriptionName = (Get-AzureRMSubscription)[0].Name                                   # Replace with the name of your preferred subscription
$CloudDriveMP = (Get-CloudDrive).MountPoint
New-PSDrive -Name "F" -PSProvider "FileSystem" -Root $CloudDriveMP
$WorkFolder = "F:\Labfiles\" ; $TempFolder = "F:\Labfiles\" 
Set-Location $WorkFolder
$NamePrefix = ("in" + (Get-Date -Format "HHmmss")).ToLower()                             # Replace "in" with your initials
$ResourceGroupName = $NamePrefix + "rg"
$StorageAccountName = $NamePrefix + "sa"
$ContainerName = $NamePrefix + "cn"
$AccountName = $NamePrefix + "account"
$AccountURI = "http://" + $AccountName
$Location = "EASTUS"
$Password = "Password333"
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force

$SP = New-AzureRmADServicePrincipal -DisplayName $AccountName -Password $SecPassword
Start-Sleep 60
New-AzureRmRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $SP.ApplicationID.GUID

$ENV:AZURE_SUBSCRIPTION_ID = (Get-AzureRMSubscription)[0].ID
$ENV:AZURE_TENANT_ID = $ID = (Get-AzureRMTenant)[0].ID
$ENV:AZURE_CLIENT_ID = $SP.ApplicationID.GUID
$ENV:AZURE_CLIENT_SECRET = $Password
$ENV:AZURE_RESOURCEGROUP_LOCATION = $Location
$ENV:AZURE_RESOURCEGROUP_NAME = $ResourceGroupName
$ENV:AZURE_STORAGEACCOUNT_NAME = $StorageAccountName
$ENV:AZURE_CONTAINER_NAME = $ContainerName
'''

import os
import json
from azure.common.credentials import ServicePrincipalCredentials
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.storage.models import StorageAccountCreateParameters
from azure.mgmt.compute import ComputeManagementClient
from azure.common.credentials import UserPassCredentials
from azure.storage import CloudStorageAccount
from azure.storage.blob.models import ContentSettings, PublicAccess
from azure.storage.file import FileService, ContentSettings

location = os.environ['AZURE_RESOURCEGROUP_LOCATION']
resourcegroupname = os.environ['AZURE_RESOURCEGROUP_NAME']
storageaccountname = os.environ['AZURE_STORAGEACCOUNT_NAME']
containername = os.environ['AZURE_CONTAINER_NAME']
subscription_id = os.environ['AZURE_SUBSCRIPTION_ID']
resource_group_params = {'location' : location}
sku = 'standard_ragrs)'
kind = 'BlobStorage'
storage_account_params = {sku:sku,kind:kind,location:location}

# Configure Credentials
credentials = ServicePrincipalCredentials(client_id=os.environ['AZURE_CLIENT_ID'],secret=os.environ['AZURE_CLIENT_SECRET'],tenant=os.environ['AZURE_TENANT_ID'])
resource_client = ResourceManagementClient(credentials, subscription_id)
storage_client = StorageManagementClient(credentials, subscription_id)

# Create Resource Group & Storage Account
resource_client.resource_groups.create_or_update(resourcegroupname, resource_group_params)
create_sa = storage_client.storage_accounts.create(resourcegroupname, storageaccountname, {'location':'eastus','kind':'storage','sku':{'name':'standard_ragrs'}})
create_sa.wait()

# Create Container
sak = storage_client.storage_accounts.list_keys(resourcegroupname, storageaccountname)
storageaccountkey = sak.keys[0].value
storage_client = CloudStorageAccount(storageaccountname, storageaccountkey)
blob_service = storage_client.create_block_blob_service()
blob_service.create_container(containername,public_access=PublicAccess.Blob)

# Copy Files
file_service = FileService(account_name=storageaccountname, account_key=storageaccountkey)
file_service.create_share(containername)
file_service.create_directory(containername, 'directory1')
file_service.create_file_from_path(containername,'directory1','55224azuresetup.ps1','55224azuresetup.ps1',)

