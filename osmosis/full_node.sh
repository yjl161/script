sudo apt install curl jq wget lz4 -y

RPC_ABCI_INFO=$(curl -s --retry 5 --retry-delay 5 --connect-timeout 30 -H "Accept: application/json" https://rpc.testnet.osmosis.zone/abci_info)
NETWORK_VERSION=$(echo $RPC_ABCI_INFO | jq  -r '.result.response.version')
wget https://github.com/osmosis-labs/osmosis/releases/download/v$NETWORK_VERSION/osmosisd-$NETWORK_VERSION-linux-amd64 -O ./osmosisd
chmod +x ./osmosisd
sudo mv ./osmosisd /usr/local/bin/osmosisd

MONIKER=blackoreo-osmosis
OSMOSIS_PORT=29
echo "export OSMOSIS_PORT=${OSMOSIS_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile
osmosisd config node tcp://localhost:${OSMOSIS_PORT}657
osmosisd init $MONIKER --chain-id osmo-test-5 --home $HOME/.osmosisd


wget -q https://genesis.testnet.osmosis.zone/genesis.json -O $HOME/.osmosisd/config/genesis.json
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${OSMOSIS_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${OSMOSIS_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${OSMOSIS_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${OSMOSIS_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${OSMOSIS_PORT}660\"%" $HOME/.osmosisd/config/config.toml
sed -i.bak -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://localhost:${OSMOSIS_PORT}317\"%; s%^address = \":8080\"%address = \":${OSMOSIS_PORT}080\"%; s%^address = \"localhost:9090\"%address = \"localhost:${OSMOSIS_PORT}090\"%; s%^address = \"localhost:9091\"%address = \"localhost:${OSMOSIS_PORT}091\"%" $HOME/.osmosisd/config/app.toml


SNAPSHOT_URL=$(curl -sL https://snapshots.testnet.osmosis.zone/latest)
wget -q -O - $SNAPSHOT_URL | lz4 -d | tar -C $HOME/.osmosisd/ -xvf -
wget -q https://rpc.testnet.osmosis.zone/addrbook -O $HOME/.osmosisd/config/addrbook.json
osmosisd start --home $HOME/.osmosisd

sudo tee /etc/systemd/system/osmosisd.service > /dev/null <<EOF
[Unit]
Description=osmosis
After=network-online.target

[Service]
User=$USER
ExecStart=$(which osmosisd) start --home $HOME/.osmosisd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable osmosisd
sudo systemctl restart osmosisd 
