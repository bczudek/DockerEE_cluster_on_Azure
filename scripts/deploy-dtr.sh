#!/bin/sh
#
# Install Docker Trusted Registry on Centos
# Based on https://github.com/microsoft/Docker-EE-on-Azure-Stack-Deployment/commits?author=stevenfollis

# UCP URL
readonly UCP_FQDN=$1

# DTR URL
readonly DTR_FQDN=$2

# Version of DTR to be installed
readonly DTR_VERSION=$3

# Node to install DTR on
readonly UCP_NODE=$(cat /etc/hostname)

# UCP Admin credentials
readonly UCP_USERNAME=$4
readonly UCP_PASSWORD=$5

checkDTR() {

    # Check if DTR exists by attempting to hit its load balancer
    STATUS=$(curl --request GET --url "https://${DTR_FQDN}/_ping" --insecure --silent --output /dev/null -w '%{http_code}' --max-time 5)
    
    echo "checkDTR: API status for ${DTR_FQDN} returned as: ${STATUS}"
    
    # Pre-Pull Images
    docker run --rm docker/dtr:"${DTR_VERSION}" images --list | xargs -L 1 docker pull

    if [ "$STATUS" -eq 200 ]; then
        echo "checkDTR: Successfully queried the DTR API. DTR is installed. Joining node to existing cluster."
        joinDTR
    else
        echo "checkDTR: Failed to query the DTR API. DTR is not installed. Installing DTR."
        installDTR
    fi

}

installDTR() {

    echo "installDTR: Installing ${DTR_VERSION} Docker Trusted Registry (DTR) on ${UCP_NODE} for UCP at ${UCP_FQDN} and with a DTR Load Balancer at ${DTR_FQDN}"

    # Install Docker Trusted Registry
    docker run \
        --rm \
        docker/dtr:${DTR_VERSION} install \
        --dtr-external-url "https://${DTR_FQDN}" \
        --ucp-url "https://${UCP_FQDN}" \
        --ucp-node "${UCP_NODE}" \
        --ucp-username "${UCP_USERNAME}" \
        --ucp-password "${UCP_PASSWORD}" \
        --ucp-insecure-tls 

    echo "installDTR: Finished installing Docker Trusted Registry (DTR)"

}

joinDTR() {

    # Get DTR Replica ID
    REPLICA_ID=$(curl --request GET --insecure --silent --url "https://${DTR_FQDN}/api/v0/meta/settings" -u "${UCP_USERNAME}":"${UCP_PASSWORD}" --header 'Accept: application/json' | jq --raw-output .replicaID)
    echo "joinDTR: Joining DTR with Replica ID ${REPLICA_ID}"

    # Join an existing Docker Trusted Registry
    docker run \
        --rm \
        docker/dtr:${DTR_VERSION} join \
        --existing-replica-id "${REPLICA_ID}" \
        --ucp-url "https://${UCP_FQDN}" \
        --ucp-node "${UCP_NODE}" \
        --ucp-username "${UCP_USERNAME}" \
        --ucp-password "${UCP_PASSWORD}" \
        --ucp-insecure-tls

}

main() {
  checkDTR
}

main