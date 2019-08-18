echo "Install UCP"

sudo cat <<EOT >> /etc/kubernetes/azure.json
{
    "cloud": "AzurePublicCloud",
    "tenantId": "$1",
    "subscriptionId": "$2",
    "aadClientId": "$3",
    "aadClientSecret": "$4",
    "resourceGroup": "$5",
    "location": "westeurope",
    "subnetName": "default",
    "securityGroupName": "$6",
    "vnetName": "$7",
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

echo "finished configuration"

echo "installing docker ucp"

sudo docker container run --rm -it --name ucp --volume /var/run/docker.sock:/var/run/docker.sock docker/ucp:3.2.0 install --host-address $(hostname -i) --pod-cidr 10.0.0.0/24 --cloud-provider Azure --admin-username "bravo" --admin-password "P@ssw0rd1" --san "vmucp.example.com" --debug > /tmp/log.txt

echo "Finished"