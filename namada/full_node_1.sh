#!/bin/bash
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install curl tar wget clang pkg-config git make libssl-dev libclang-dev libclang-12-dev
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install jq build-essential bsdmainutils ncdu gcc git-core chrony liblz4-tool
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install original-awk uidmap dbus-user-session protobuf-compiler unzip libudev-dev
reboot
