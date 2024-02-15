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

echo export NAMADA_CHAIN_ID=${NAMADA_CHAIN_ID} >> $HOME/.bash_profile
echo export NAMADA_TRUSTING_PERIOD=${NAMADA_TRUSTING_PERIOD} >> $HOME/.bash_profile
echo export NAMADA_RELAYER=${NAMADA_RELAYER} >> $HOME/.bash_profile
echo export NAMADA_DENOM=${NAMADA_DENOM} >> $HOME/.bash_profile
source ~/.bash_profile

wget https://github.com/heliaxdev/hermes/releases/download/v1.7.4-namada-beta7/hermes-v1.7.4-namada-beta7-x86_64-unknown-linux-gnu.zip
sudo apt-get install unzip -y
unzip hermes-v1.7.4-namada-beta7-x86_64-unknown-linux-gnu.zip
cp hermes /usr/local/bin/
rm -rf hermes-v1.7.4-namada-beta7-x86_64-unknown-linux-gnu.zip

wget -O config.toml https://raw.githubusercontent.com/LUNA007KING/script/main/namada/hermes_config.toml
sed -i 's/NAMADA_CHAIN_ID/$NAMADA_CHAIN_ID/g' config.toml
sed -i 's/NAMADA_TRUSTING_PERIOD/$NAMADA_TRUSTING_PERIOD/g' config.toml
sed -i 's/NAMADA_RELAYER/$NAMADA_RELAYER/g' config.toml
sed -i 's/NAMADA_DENOM/$NAMADA_DENOM/g' config.toml

cp config.toml /root/.hermes/config.toml
