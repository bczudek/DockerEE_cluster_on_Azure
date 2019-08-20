$ErrorActionPreference = "Stop"

$ssh="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6KKNcjy35YVgZvO29xuUn/KmmQWa6Azj7BydrwCD9aZRP8vtS6iRmigibWBePBeBOqKUj90qzAOgHT5Vta3PESap9SbXEaLw4yChE3ZIciBXNI8dE5og5ntDRbUi/Fbe2JJnkd43nQ0yr4XvobRsxIJkL1hciHPlvM3F+83kPOU6/YIcafYwnXOjGgRqLptq9AAoJlvjAbZBGRvWU34O4WdeMdcvCySinbyQxB72sOR7wcQKNKoZX/8LQwXufbqdY6TGVCGiE04OemgeksMglyetRxRYyql3F98qZXrCvUE04eryo9W/VMZd/Zj7KPoBz87LQBmyZCXPoIAeeFdMKob7KlayPHvDI+9FY1KO+gsWTs1ceA3o5DZ/s71duCCi2IEfyxdfwivBYHoVV7yMd9uBe5NFAqr+jU9HVs/v0U0DM3L+BT8SEhNhs+ZRm5ejWGdVLpZINqkw3gFkQ1ygqQ/QPaLkgNsku8hpRnfgLzqtJ//tpbc46NI/630Ucb/cEsvsYeOAC12KinEjPNhlWYSJAhVQG80Z8gGtOJEUc3wVWmVRwRYI/jw7FrWZy65tKEMI7N82xUBkSXJ5Cdvq8p6GHPBn5s3vpHeaUyoXPwqTdNmrs7AG9TRhrju4m261L8ord/c/RKgSiSFj60QJLb+sDUF/PBiOiS1jUHWGFLw== bartlomiej.czudek@capgemini.com"
$dockerURL = "https://storebits.docker.com/ee/centos/sub-396efa35-0cee-43f6-9a04-98712c7b2edb"

$version = '12'
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