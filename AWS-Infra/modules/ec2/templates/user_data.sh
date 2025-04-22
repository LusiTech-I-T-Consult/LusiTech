#!/bin/bash

# Remove any old Docker versions
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

# System update & install dependencies
sudo apt update -y
sudo apt install -y ca-certificates curl gnupg

# Setup Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repo to apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update -y

# Install Docker components (Compose V2 included)
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker and enable it on boot
sudo systemctl start docker
sudo systemctl enable docker

# (Optional) Install Compose V2 manually as CLI plugin — only needed if not using the plugin package
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Add current user to docker group
sudo usermod -aG docker $USER
cd /home/ubuntu
git clone https://github.com/LusiTech-I-T-Consult/LusiTech.git
cd LusiTech
sudo docker compose up --build -d
