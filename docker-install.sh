#!/bin/bash

echo "Docker install..."
apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io
echo "Docker install success."

echo "Pull v2ray image..."
docker pull v2ray/official
echo "Make v2ray config dir..."
mkdir -m 777 /etc/v2ray
