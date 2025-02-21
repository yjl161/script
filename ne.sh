NEXUS_HOME="$HOME/.nexus"
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
NC='\033[0m'

[ -d "$NEXUS_HOME" ] || mkdir -p "$NEXUS_HOME"

NODE_ID="9294801"
echo "$NODE_ID" > "$NEXUS_HOME/node-id"

git --version 2>&1 >/dev/null
GIT_IS_AVAILABLE=$?
if [ "$GIT_IS_AVAILABLE" != 0 ]; then
  echo "Unable to find git. Please install it and try again."
  exit 1
fi

REPO_PATH="$NEXUS_HOME/network-api"
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

(
  cd "$REPO_PATH" || exit
  git -c advice.detachedHead=false checkout "$(git rev-list --tags --max-count=1)"
)

cd $HOME/.nexus/network-api/clients/cli

SCREEN_SESSION="nexus_prover"
screen -dmS "$SCREEN_SESSION" bash -c "
  echo \"y\" | (
    cargo run -r -- start --env beta
  )
"
