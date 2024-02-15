echo "============================================================"
echo "Install start"
echo "============================================================"
echo "Enter Namada Chain Id:"
read NAMADA_CHAIN_ID
echo "============================================================"
echo "Enter Namada Trusting Period:"
read NAMADA_TRUSTING_PERIOD
echo "============================================================"
echo "Enter Namada Relayer Key:"
read NAMADA_RELAYER
echo "============================================================"
echo "Enter Namada Denom:"
read NAMADA_DENOM
echo "============================================================"
echo "Enter Osmo Relayer Seed:"
read OSMO_RELAYER_SEED
echo "============================================================"
echo "Enter Osmo RPC Port:"
read OSMO_RPC_PORT
echo "============================================================"
echo "Enter Osmo GRPC Port:"
read OSMO_GRPC_PORT
echo "============================================================"

echo export NAMADA_CHAIN_ID=${NAMADA_CHAIN_ID} >> $HOME/.bash_profile
echo export NAMADA_TRUSTING_PERIOD=${NAMADA_TRUSTING_PERIOD} >> $HOME/.bash_profile
echo export NAMADA_RELAYER=${NAMADA_RELAYER} >> $HOME/.bash_profile
echo export NAMADA_DENOM=${NAMADA_DENOM} >> $HOME/.bash_profile
echo $OSMO_RELAYER_SEED > osmo_relayer_seed
echo export OSMO_RPC_PORT=${OSMO_RPC_PORT} >> $HOME/.bash_profile
echo export OSMO_GRPC_PORT=${OSMO_GRPC_PORT} >> $HOME/.bash_profile
source ~/.bash_profile

wget https://github.com/heliaxdev/hermes/releases/download/v1.7.4-namada-beta7/hermes-v1.7.4-namada-beta7-x86_64-unknown-linux-gnu.zip
sudo apt-get install unzip -y
unzip hermes-v1.7.4-namada-beta7-x86_64-unknown-linux-gnu.zip
cp hermes /usr/local/bin/

wget -O config.toml https://raw.githubusercontent.com/LUNA007KING/script/main/namada/hermes_config.toml
sed -i "s/NAMADA_CHAIN_ID/$NAMADA_CHAIN_ID/g" config.toml
sed -i "s/NAMADA_TRUSTING_PERIOD/$NAMADA_TRUSTING_PERIOD/g" config.toml
sed -i "s/NAMADA_RELAYER/$NAMADA_RELAYER/g" config.toml
sed -i "s/NAMADA_DENOM/$NAMADA_DENOM/g" config.toml
sed -i "s/OSMO_RPC_PORT/$OSMO_RPC_PORT/g" config.toml
sed -i "s/OSMO_GRPC_PORT/$OSMO_GRPC_PORT/g" config.toml

mkdir /root/.hermes
cp config.toml /root/.hermes/config.toml

hermes keys add --chain $NAMADA_CHAIN_ID --key-file $HOME/.local/share/namada/$NAMADA_CHAIN_ID/wallet.toml
hermes keys add --chain osmo-test-5 --mnemonic-file osmo_relayer_seed
hermes create channel --a-chain $NAMADA_CHAIN_ID --b-chain osmo-test-5 --a-port transfer --b-port transfer --new-client-connection --yes
rm -rf hermes
rm -rf config.toml
rm -rf hermes-v1.7.4-namada-beta7-x86_64-unknown-linux-gnu.zip
rm -rf osmo_relayer_seed

sudo tee /etc/systemd/system/hermesd.service > /dev/null <<EOF
[Unit]
Description=Hermes IBC Relayer
After=network-online.target
StartLimitIntervalSec=0
[Service]
User=root 
ExecStart=hermes start
Restart=always 
RestartSec=120
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hermesd
sudo systemctl restart hermesd


