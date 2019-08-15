$ErrorActionPreference = "Stop"

$rg = 'rg_docker'

Write-Host 'Deploying resource group'
az deployment create `
    --name d_reg `
    --location westeurope `
    --template-file .\docker_rg.json `
    --parameters rgName=$rg

Write-Host 'Deploying network'
az group deployment create `
    --name d_network `
    -g $rg `
    --template-file .\docker_network.json `

Write-Host 'Deploying ucp vm'
az group deployment create `
    --name d_ucp `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.ucp.parameters.json

Write-Host 'Deploying dtr vm'
az group deployment create `
    --name d_dtr `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.dtr.parameters.json

Write-Host 'Deploying wkr vm'
az group deployment create `
    --name d_wkr `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.wkr.parameters.json

Write-Host 'Deploying test vm'
az group deployment create `
    --name d_test `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.test.parameters.json

    