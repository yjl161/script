sudo tee /etc/systemd/system/nillion-accuser.service > /dev/null << EOF
[Unit]
Description=Nillion Accuser Service
After=docker.service
Requires=docker.service

[Service]
User=$USER
ExecStart=/usr/bin/docker run -v $HOME/nillion/accuser:/var/tmp nillion/retailtoken-accuser:latest accuse --rpc-endpoint "https://testnet-nillion-rpc.lavenderfive.com/" --block-start "$(curl -s https://testnet-nillion-rpc.lavenderfive.com/abci_info | jq -r '.result.response.last_block_height')"


Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置
sudo systemctl daemon-reload

# 启用并启动服务
sudo systemctl enable nillion-accuser.service
sudo systemctl start nillion-accuser.service
