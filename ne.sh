#!/bin/sh

# Update system and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl pkg-config libssl-dev protobuf-compiler screen unzip
sudo apt install -y cargo 
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
rustup update
curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.2/protoc-25.2-linux-x86_64.zip
unzip protoc-25.2-linux-x86_64.zip -d $HOME/.local
export PATH="$HOME/.local/bin:$PATH"

# Swap file setup
sudo swapoff -a
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

rustup target add riscv32i-unknown-none-elf

# Nexus home and node-id setup
NEXUS_HOME="$HOME/.nexus"
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
NC='\033[0m'

[ -d "$NEXUS_HOME" ] || mkdir -p "$NEXUS_HOME"
NODE_ID="9294801"
echo "$NODE_ID" > "$NEXUS_HOME/node-id"

# Check if git is available
git --version 2>&1 >/dev/null
GIT_IS_AVAILABLE=$?
if [ "$GIT_IS_AVAILABLE" != 0 ]; then
  echo "Unable to find git. Please install it and try again."
  exit 1
fi

REPO_PATH="$NEXUS_HOME/network-api"

# Clone or update the repository
if [ -d "$REPO_PATH" ]; then
  echo "$REPO_PATH exists. Updating."
  (
    cd "$REPO_PATH" || exit
    git stash
    git fetch --tags
  )
else
  (
    cd "$NEXUS_HOME" || exit
    git clone https://github.com/nexus-xyz/network-api
  )
fi

# Check out the latest tagged commit
(
  cd "$REPO_PATH" || exit
  git -c advice.detachedHead=false checkout "$(git rev-list --tags --max-count=1)"
)

# Check if there are uncommitted changes (which could indicate the repo is not fully updated)
(
  cd "$REPO_PATH" || exit
  if git diff-index --quiet HEAD --; then
    echo "Repository is clean and up-to-date."
  else
    echo "Repository has uncommitted changes. Please commit or discard them."
    exit 1
  fi
)

# Wait until cargo dependencies are installed and the project is ready
echo "Ensuring cargo dependencies are up to date..."
(
  cd "$HOME/.nexus/network-api" || exit
  cargo fetch
  cargo build --release
)

# Navigate to the cli directory
cd $HOME/.nexus/network-api/clients/cli

# Create a new screen session to run the cargo command
SCREEN_SESSION="nexus_prover"
screen -dmS "$SCREEN_SESSION" bash -c "
  source ~/.bashrc
  echo 'y' | cargo run -r -- start --env beta > ~/nexus_prover_log.txt 2>&1
"
