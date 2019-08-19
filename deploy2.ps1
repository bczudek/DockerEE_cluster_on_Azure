$ErrorActionPreference = "Stop"

$rg = 'rg_docker12'
$sp_name = "dockersp12"
$sp = ((az ad sp create-for-rbac --name $sp_name) | ConvertFrom-Json)
az role assignment create --assignee ("http://$($sp_name)") --role "Contributor"
$appId = $sp.appId
$pwd = $sp.password
$storageName = "scriptstoragedocker12"
$domainName = "mydockerkrakow12"
$securityGroupName = "nsg_docker"


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
    --parameters sa_name=$storageName

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
    --parameters sa_name=$storageName `
    --parameters domainPrefix=$domainName `
    --parameters ssh="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdq43jcMlg5Kr3tDaInGcuhBHAaBU4mwEHkHeqAIuOsBTA6sRmllyj34fFDCjXMZKM+4GXmfzunnthBHozl5CbSzu+Weh019gwW05gYTvxkw4GK3nszhq2lF8dUy592edG/0Mc78qTbk46x3ji8HQARtZseWDGvL+Rr4zZDPnqedydXB/4tM+hvSsEkhOPL9AMme8AxbXfdhvhqA8ZEH0VEzmTjzkwSTryV7mIAVM6H/CjLgEvf43881S+8YxA0Sq3kTEOptpgRBkUAhtvVWk7StygE3NnAUmz8CqEdrMRfjgXuSpAXw1EUl3k2llo1coz3ClS9zCaiU/PhWSTFVEdeExs89C5y7VLqDSQE8nLin5XFFZGcXktPYOnUfvF8xepjc+7zPRIyfHZ3+ftVT1UlmiXtegBqurJpMLC3DlN0Yo7xNG5D6P8YAMPJy5dnalzq2Gs0aDLXgA9z9lrgjgzwW19zITntuQOjbkGSaz/dt87XJnvS00ypk6HBvaqzWphW6slcoqHlmQZ2+20xqeu+pgxtaTc1DZGTlryTNFCAqCMjZYtbjlimU4QPmei280GPG1k4yghTmPzwf4NPcNcXDK36CA/S9IWwPhtlKnJfdivB2mYsMFG6LsTdK50leNFZh2NHgFsWmBpUMqmGHpMjAxomg/EfDM1nPCF3HzZ2w== bartl@DESKTOP-G60PJ8S" `
    --parameters storage_account_name=$storageName `
    --parameters storage_account_key=$storage_key `
    --parameters aadClient_id=$appId `
    --parameters aad_client_secret=$pwd `
    --parameters security_group_name=$securityGroupName