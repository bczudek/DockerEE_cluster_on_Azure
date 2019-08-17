echo "Install UCP"
docker container run --rm -it \
  --name ucp \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  docker/ucp:3.2.0 install \
  --host-address 10.0.0.4 \
  --pod-cidr 10.0.0.0/24 \
  --cloud-provider Azure \
  --admin-username "bravo" \
  --admin-password "P@ssw0rd1" \
  --san "vmucp.example.com"

echo "Finished"