#!/bin/bash

sudo apt-get update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
sudo systemctl start docker
sudo systemctl enable docker

#Linha de comando para rodar nas máquinas que farão parte do cluster com as roles: etcd, control plane e worker (configurável)
sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run rancher/rancher-agent:v2.4.18 --server https://ec2-35-172-119-193.compute-1.amazonaws.com --token t9l4789g74bzl48cwjxm7xqnq7cd4lpjqt664n2ll92fdnw5w42gzd --ca-checksum ef2ec8e580b3b0646204ebb445f9bde628735412ff0d6db56f17cab392633902 --etcd --controlplane --worker