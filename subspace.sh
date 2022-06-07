#!/bin/bash

echo "============================================================"
echo "Install start"
echo "============================================================"
echo "Enter node name:"
read NODE_NAME
echo "============================================================"
echo "Enter wallet:"
read WALLET
echo "============================================================"
echo "Enter plot size:"
read PLOT_SIZE
echo export NODE_NAME=${NODE_NAME} >> $HOME/.bash_profile
echo export WALLET=${WALLET} >> $HOME/.bash_profile
echo export PLOT_SIZE=${PLOT_SIZE} >> $HOME/.bash_profile
source ~/.bash_profile

sleep 2

echo -e "\e[1m\e[32m1. Remove Old Version \e[0m" && sleep 1
# remove
sudo systemctl stop subspace-node subspace-farmer
sudo systemctl disable subspace-node subspace-farmer
sudo deluser subspace
sudo rm -rf /var/lib/subspace
sudo rm -rf /root/.local/share/subspace*
sudo rm /usr/local/bin/subspace*
sudo rm /etc/systemd/system/subspace*

echo -e "\e[1m\e[32m2. Install docker-compose \e[0m" && sleep 1
cd $HOME
sudo apt update && sudo apt purge docker docker-engine docker.io containerd docker-compose -y
rm /usr/bin/docker-compose /usr/local/bin/docker-compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo -e "\e[1m\e[32m3. Subspace Docer-compose yml \e[0m" && sleep 1
mkdir $HOME/subspace
cd $HOME/subspace

tee $HOME/subspace/docker-compose.yml > /dev/null <<EOF
version: "3.7"
services:
  node:
    image: ghcr.io/subspace/node:gemini-1b-2022-june-05
    volumes:
      - node-data:/var/subspace:rw
    ports:
      - "0.0.0.0:30333:30333"
    restart: unless-stopped
    command: [
      "--chain", "gemini-1",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--pruning", "1024",
      "--keep-blocks", "1024",
      "--port", "30333",
      "--rpc-cors", "all",
      "--rpc-methods", "safe",
      "--unsafe-ws-external",
      "--validator",
      "--name", "$NODE_NAME"
    ]
    healthcheck:
      timeout: 5s
      interval: 30s
      retries: 5

  farmer:
    depends_on:
      node:
        condition: service_healthy
    image: ghcr.io/subspace/farmer:gemini-1b-2022-june-05
    ports:
      - "127.0.0.1:9955:9955"
    volumes:
      - farmer-data:/var/subspace:rw
    restart: unless-stopped
    command: [
      "--base-path", "/var/subspace",
      "farm",
      "--node-rpc-url", "ws://node:9944",
      "--ws-server-listen-addr", "0.0.0.0:9955",
      "--reward-address", "$WALLET",
      "--plot-size", "$PLOT_SIZE"
    ]
volumes:
  node-data:
  farmer-data:
EOF

echo -e "\e[1m\e[32m4. Setup Subspace Node and Farmer \e[0m" && sleep 1
docker-compose up -d
