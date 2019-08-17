echo "ho"
export DOCKERURL="https://storebits.docker.com/ee/centos/sub-396efa35-0cee-43f6-9a04-98712c7b2edb"
sudo -E sh -c 'echo "$DOCKERURL/centos" > /etc/yum/vars/dockerurl'
echo "ho"
