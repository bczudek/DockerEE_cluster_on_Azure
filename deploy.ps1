$ErrorActionPreference = "Stop"

$rg = 'rg_docker4'

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

Write-Host 'Deploying ucp'
az group deployment create `
    --name d_ucp `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.ucp.parameters.json

Write-Host 'Deploying dtr'
az group deployment create `
    --name d_dtr `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.dtr.parameters.json

Write-Host 'Deploying resource wkr'
az group deployment create `
    --name d_wkr `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.wkr.parameters.json