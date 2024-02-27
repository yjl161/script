#!/bin/bash

echo "============================================================"
echo "Install start"
echo "============================================================"
echo "Enter Namada Version:"
read NAMADA_TAG
echo "============================================================"
echo "Enter Chain Id:"
read CHAIN_ID
echo "============================================================"
echo "Enter CBFT:"
read CBFT
echo "============================================================"
echo "Enter Testnet Flag:"
read IS_TESTNET
echo "============================================================"

echo export NAMADA_TAG=${NAMADA_TAG} >> $HOME/.bash_profile
echo export CBFT=${CBFT} >> $HOME/.bash_profile
echo export NAMADA_CHAIN_ID=${CHAIN_ID} >> $HOME/.bash_profile
echo export IS_TESTNET=${IS_TESTNET} >> $HOME/.bash_profile
echo "export BASE_DIR=$HOME/.local/share/namada" >> ~/.bash_profile
source ~/.bash_profile

sudo curl https://sh.rustup.rs --proto '=https' --tlsv1.2 -sSf | sh -s -- -y
source "$HOME/.cargo/env"

curl https://deb.nodesource.com/setup_18.x | sudo bash
sudo apt install cargo nodejs -y < "/dev/null"

cargo --version
node -v

if ! [ -x "$(command -v go)" ]; then
  ver="1.21.3"
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
fi

cd $HOME && rustup update
PROTOC_ZIP=protoc-23.3-linux-x86_64.zip
curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v23.3/$PROTOC_ZIP
sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc
sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*'
rm -f $PROTOC_ZIP

cd $HOME && git clone https://github.com/anoma/namada && cd namada && git checkout $NAMADA_TAG
make build-release

cd $HOME && git clone https://github.com/cometbft/cometbft.git && cd cometbft && git checkout $CBFT
make build

cd $HOME && cp $HOME/cometbft/build/cometbft /usr/local/bin/cometbft && \
cp "$HOME/namada/target/release/namada" /usr/local/bin/namada && \
cp "$HOME/namada/target/release/namadac" /usr/local/bin/namadac && \
cp "$HOME/namada/target/release/namadan" /usr/local/bin/namadan && \
cp "$HOME/namada/target/release/namadaw" /usr/local/bin/namadaw && \
cp "$HOME/namada/target/release/namadar" /usr/local/bin/namadar

cometbft version
namada --version

if [ "$IS_TESTNET" = "true" ]; then
    export NAMADA_NETWORK_CONFIGS_SERVER=https://testnet.luminara.icu/configs
    namada client utils join-network --chain-id $NAMADA_CHAIN_ID --dont-prefetch-wasm
    wget https://testnet.luminara.icu/wasm.tar.gz
    tar -xf wasm.tar.gz
    cp wasm/* ~/.local/share/namada/$NAMADA_CHAIN_ID/wasm/
    curl -O https://testnet.luminara.icu/luminara.env
    PERSISTENT_PEERS=$(grep -oP 'PERSISTENT_PEERS="\K[^"]+' luminara.env)
    sed -i "s/persistent_peers = \".*\"/persistent_peers = \"$PERSISTENT_PEERS\"/" ~/.local/share/namada/$NAMADA_CHAIN_ID/config.toml
    rm -rf luminara.env
else
    namada client utils join-network --chain-id $NAMADA_CHAIN_ID
fi

rm -rf wasm*
sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' ~/.local/share/namada/$NAMADA_CHAIN_ID/config.toml
sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "0ms"/' ~/.local/share/namada/$NAMADA_CHAIN_ID/config.toml
sed -i 's/indexer = "null"/indexer = "kv"/g' ~/.local/share/namada/$NAMADA_CHAIN_ID/config.toml


sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.local/share/namada
Environment=TM_LOG_LEVEL=p2p:none,pex:error
Environment=NAMADA_CMT_STDOUT=true
ExecStart=/usr/local/bin/namada node ledger run
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl restart namadad
