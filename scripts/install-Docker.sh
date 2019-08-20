# Docker URL
readonly DOCKERURL=$1

instalDocker() {
    echo "Installing Docker"

    sudo -E sh -c "echo '${DOCKERURL}/centos' > /etc/yum/vars/dockerurl"

    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo yum install epel-release -y
    sudo yum install jq -y

    sudo -E yum-config-manager --add-repo "${DOCKERURL}/centos/docker-ee.repo"

    sudo yum -y install docker-ee docker-ee-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker bravo

    sudo mkdir -p /etc/kubernetes

    echo "Finished docker installation"
}

main() {
  instalDocker
}

main