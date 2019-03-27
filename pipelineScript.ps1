# @uthor Shiv Mangal Singh

## Defining Variables ##

Param (
    [string]$storageAccountName = $env:storageAccountName,
    [string]$resourceGroupName = $env:resourceGroupName,
    [string]$containerName = $env:containerName,
    [string]$location = $env:location,
    [string]$templateFile = $env:templateFile,
    [string]$parametersFile = $env:parametersFile,
    [string]$artifactsRootDirectory = $env:artifactsRootDirectory
)


## Create a resource group if not present ##

Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorVariable resourceGroupNotPresent -ErrorAction SilentlyContinue

if ($resourceGroupNotPresent)
{
    # ResourceGroup doesn't exist
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}

## Create an Azure Storage Account ##

Get-AzureRMStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName -ErrorVariable storageNotPresent -ErrorAction SilentlyContinue

if ($storageNotPresent){
    New-AzureRMStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccountName -Location $location -SkuName "Standard_LRS" -Kind Storage
}


## Retrieving storage context using key ##

$accountKey = (Get-AzureRMStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
$context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $accountKey 


## Create a storage container if not already present ##

Get-AzureStorageContainer -Name $containerName -Context $context -ErrorVariable storageContainerNotPresent -ErrorAction SilentlyContinue

if ($storageContainerNotPresent)
{
New-AzureStorageContainer -Name $containerName -Context $context -Permission Container
}


## Uploading Resource template files to the container ##

Set-AzureStorageBlobContent -File "$artifactsRootDirectory\$templateFile" -Context $context -Container $containerName
#Set-AzureStorageBlobContent -File "$Env:BUILD_SOURCESDIRECTORY\Parameters.json" -Context $context -Container $containerName
Set-AzureStorageBlobContent -File "$artifactsRootDirectory\$parametersFile" -Context $context -Container $containerName


$templatePath = "https://" + $storageAccountName + ".blob.core.windows.net/" + $containerName + "/" + $templateFile
$parametersPath = "https://" + $storageAccountName + ".blob.core.windows.net/" + $containerName + "/" + $parametersFile

#$password = (ConvertTo-SecureString (Get-AzureKeyVaultSecret -vaultName 'shiv-g-vault' -name "ExamplePassword") -AsPlainText -Force)

## Deploying resources on Azure using templates stored in a container
## in a storage account

New-AzureRMResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "myDeployment" -TemplateUri $templatePath -TemplateParameterUri $parametersPath
