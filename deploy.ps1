$ErrorActionPreference = "Stop"

$ssh=""
$dockerURL = ""

$version = '1'
$rg = 'rg_docker' + $version
$sp_name = "dockersp" + $version
$storageName = "scriptstoragedocker" + $version
$domainName = "mydockerkrakow" + $version
$securityGroupName = "nsg_docker"
$vnet_name = "vnet_docker"

$sp = ((az ad sp create-for-rbac --name $sp_name) | ConvertFrom-Json)
az role assignment create --assignee ("http://$($sp_name)") --role "Contributor"
$appId = $sp.appId
$pwd = $sp.password

Write-Host 'Deploying resource group'
az deployment create `
    --name d_reg `
    --location westeurope `
    --template-file .\docker_rg.json `
    --parameters rgName=$rg

Write-Host 'Deploying network and storage'
az group deployment create `
    --name d_network_storage `
    -g $rg `
    --template-file .\docker_network_storage.json `
    --parameters sa_name=$storageName `
    --parameters nsg_name=$securityGroupName `
    --parameters vnet_name=$vnet_name

$storage_key = ((az storage account keys list --account-name $storageName) | ConvertFrom-Json)[0].value

az storage blob upload-batch `
    -d "scripts" -s ./scripts/ `
    --account-name $storageName `
    --account-key $storage_Key

Write-Host 'Deploying ucp'
az group deployment create `
    --name d_ucp `
    -g $rg `
    --template-file .\docker_vms.json `
    --parameters docker_url=$dockerURL `
    --parameters domainPrefix=$domainName `
    --parameters ssh=$ssh `
    --parameters storage_account_name=$storageName `
    --parameters storage_account_key=$storage_key `
    --parameters aadClient_id=$appId `
    --parameters aad_client_secret=$pwd `
    --parameters security_group_name=$securityGroupName `
    --parameters vnet_name=$vnet_name `
    --debug