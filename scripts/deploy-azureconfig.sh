    #azure configuration
readonly TENANT_ID=$1
readonly SUBSCRIPTION_ID=$2
readonly AAD_CLIENT_ID=$3
readonly AAD_CLIENT_SECRET=$4
readonly RESOURCE_GROUP=$5
readonly LOCATION=$6
readonly SECURITY_GROUP_NAME=$7
readonly VNET_NAME=$8
    
echo "setting up config for azure"
sudo cat <<EOT >> /etc/kubernetes/azure.json
{
    "cloud": "AzurePublicCloud",
    "tenantId": "${TENANT_ID}",
    "subscriptionId": "${SUBSCRIPTION_ID}",
    "aadClientId": "${AAD_CLIENT_ID}",
    "aadClientSecret": "${AAD_CLIENT_SECRET}",
    "resourceGroup": "${RESOURCE_GROUP}",
    "location": "${LOCATION}",
    "subnetName": "default",
    "securityGroupName": "${SECURITY_GROUP_NAME}",
    "vnetName": "${VNET_NAME}",
    "cloudProviderBackoff": false,
    "cloudProviderBackoffRetries": 0,
    "cloudProviderBackoffExponent": 0,
    "cloudProviderBackoffDuration": 0,
    "cloudProviderBackoffJitter": 0,
    "cloudProviderRatelimit": false,
    "cloudProviderRateLimitQPS": 0,
    "cloudProviderRateLimitBucket": 0,
    "useManagedIdentityExtension": false,
    "useInstanceMetadata": true
}
EOT

sudo chmod 0644 /etc/kubernetes/azure.json
echo "finished azure configuration"