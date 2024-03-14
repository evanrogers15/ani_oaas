#!/bin/bash

# Check if yum-utils is installed
if ! yum list installed yum-utils &>/dev/null; then
  sudo yum install -y yum-utils
fi

# Check if jq is installed
if ! yum list installed jq &>/dev/null; then
  sudo yum install -y jq
fi

# Check if openssl is installed
if ! yum list installed openssl &>/dev/null; then
  sudo yum install -y openssl
fi

# Add Docker CE repository
if ! yum repolist enabled | grep -q "docker-ce.repo"; then
  sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
fi

# Check if Docker CE and its dependencies are installed
if ! yum list installed docker-ce &>/dev/null ||
   ! yum list installed docker-ce-cli &>/dev/null ||
   ! yum list installed containerd.io &>/dev/null ||
   ! yum list installed docker-compose-plugin &>/dev/null; then
  sudo yum -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

yum -y install bash-completion

# Start and enable the Docker service
if ! systemctl is-active --quiet docker; then
  sudo systemctl start docker
fi

if ! systemctl is-enabled docker; then
  sudo systemctl enable docker
fi