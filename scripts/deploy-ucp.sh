#!/bin/sh
#
# Install Docker Universal Control Plane on Ubuntu

# UCP URL
readonly UCP_FQDN=$1

# External Service Load Balancer URL
readonly APPS_LB_FQDN=$2

# Is node a worker or manager?
readonly NODE_ROLE=$3

# Version of UCP to be installed
readonly UCP_VERSION=$4

# Name of current node
readonly NODE_NAME=$(cat /etc/hostname)

# UCP Administrator Credentials
readonly UCP_ADMIN="admin"
readonly UCP_PASSWORD="Docker123!"

#azure configuration
readonly TENANT_ID=$5
readonly SUBSCRIPTION_ID=$6
readonly AAD_CLIENT_ID=$7
readonly AAD_CLIENT_SECRET=$8
readonly RESOURCE_GROUP=$9
readonly LOCATION="${10}"
readonly SECURITY_GROUP_NAME="${11}"
readonly VNET_NAME="${12}"

# Install jq library for parsing JSON
sudo yum install epel-release -y
sudo yum install jq -y

checkUCP() {

    # Check if UCP exists by attempting to hit its load balancer
    STATUS=$(curl --request GET --url "https://${UCP_FQDN}" --insecure --silent --output /dev/null -w '%{http_code}' --max-time 5)
    
    echo "checkUCP: API status for ${UCP_FQDN} returned as: ${STATUS}"

    if [ "$STATUS" -eq 200 ]; then
        echo "checkUCP: Successfully queried the UCP API. UCP is installed. Joining node to existing cluster."
        joinUCP
    else
        echo "checkUCP: Failed to query the UCP API. UCP is not installed. Installing UCP."
        installUCP
    fi

}

installUCP() {
    echo "${UCP_FQDN}"
    echo "${APPS_LB_FQDN}"
    echo "${NODE_ROLE}"
    echo "${UCP_VERSION}"
    echo "${NODE_NAME}"
    echo "${UCP_ADMIN}"
    echo "${UCP_PASSWORD}"
    echo "${TENANT_ID}"
    echo "${SUBSCRIPTION_ID}"
    echo "${AAD_CLIENT_ID}"
    echo "${AAD_CLIENT_SECRET}"
    echo "${RESOURCE_GROUP}"
    echo "${LOCATION}"
    echo "${SECURITY_GROUP_NAME}"
    echo "${VNET_NAME}"

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

    echo "installUCP: Installing Docker Universal Control Plane (UCP)"

    # Install Universal Control Plane
    sudo docker run \
        --rm \
        --name ucp \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        docker/ucp:"${UCP_VERSION}" install \
        --host-address $(hostname -i) \
        --pod-cidr 10.0.0.0/24 \
        --cloud-provider azure \
        --admin-username "${UCP_ADMIN}" \
        --admin-password "${UCP_PASSWORD}" \
        --san "${UCP_FQDN}" \
        --external-service-lb "${APPS_LB_FQDN}"

    # Wait for node to reach a ready state
    # until [ $(curl --request GET --url "https://${UCP_FQDN}/_ping" --insecure --silent --header 'Accept: application/json' | grep OK) ]
    # do
    #     echo '...created cluster, waiting for a ready state'
    #     sleep 5
    # done

    sleep 5

    echo "installUCP: Cluster's ping returned a ready state"

    echo "installUCP: Finished installing Docker Universal Control Plane (UCP)"

}

joinUCP() {

    # Get Authentication Token
    AUTH_TOKEN=$(curl --request POST --url "https://${UCP_FQDN}/auth/login" --insecure --silent --header 'Accept: application/json' --data '{ "username": "'${UCP_ADMIN}'", "password": "'${UCP_PASSWORD}'" }' | jq --raw-output .auth_token)

    # Get Swarm Manager IP Address + Port
    UCP_MANAGER_ADDRESS=$(curl --request GET --url "https://${UCP_FQDN}/info" --insecure --silent --header 'Accept: application/json' --header "Authorization: Bearer ${AUTH_TOKEN}" | jq --raw-output .Swarm.RemoteManagers[0].Addr)
    
    # Get Swarm Join Tokens
    UCP_JOIN_TOKENS=$(curl --request GET --url "https://${UCP_FQDN}/swarm" --insecure --silent --header 'Accept: application/json' --header "Authorization: Bearer ${AUTH_TOKEN}" | jq .JoinTokens)
    UCP_JOIN_TOKEN_MANAGER=$(echo "${UCP_JOIN_TOKENS}" | jq --raw-output .Manager)
    UCP_JOIN_TOKEN_WORKER=$(echo "${UCP_JOIN_TOKENS}" | jq --raw-output .Worker)

    # Join Swarm
    if [ "$NODE_ROLE" = "Manager" ]
    then
        echo "joinUCP: Joining Swarm as a Manager"
        docker swarm join --token "${UCP_JOIN_TOKEN_MANAGER}" "${UCP_MANAGER_ADDRESS}"
    else
        echo "joinUCP: Joining Swarm as a Worker"
        docker swarm join --token "${UCP_JOIN_TOKEN_WORKER}" "${UCP_MANAGER_ADDRESS}"
    fi

    # Wait for node to reach a ready state
    # while [ "$(curl --request GET --url "https://${UCP_FQDN}/nodes/${NODE_NAME}" --insecure --silent --header 'Accept: application/json' --header "Authorization: Bearer ${AUTH_TOKEN}" | jq --raw-output .Status.State)" != "ready" ]
    # do
    #     echo '...node joined, waiting for a ready state'
    #     sleep 5
    # done

    sleep 5

    echo "joinUCP: Finished joining node to UCP"

}

main() {
  checkUCP
}

main