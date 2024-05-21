echo "============================================================"
echo "Enter Domain:"
read DOMAIN
echo "============================================================"
echo "Enter Email:"
read EMAIL
echo "============================================================"
echo "Enter Port:"
read PORT
echo "============================================================"
echo "Enter Type:"
read TYPE
echo "============================================================"
echo "Do you want to delete all configurations in /etc/nginx/sites-available and /etc/nginx/sites-enabled? (yes/no):"
read DELETE_CONFIRM
echo "============================================================"

export DOMAIN=$DOMAIN
export EMAIL=$EMAIL
export PORT=$PORT
export TYPE=$TYPE

sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install nginx
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

if [ "$DELETE_CONFIRM" = "yes" ]; then
    sudo rm -rf /etc/nginx/sites-available/*
    sudo rm -rf /etc/nginx/sites-enabled/*
fi

sudo tee /etc/nginx/sites-available/$TYPE-initia > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
         }
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';

        proxy_pass http://localhost:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/$TYPE-initia /etc/nginx/sites-enabled/

cd /etc/nginx/sites-enabled/
sudo rm -f default
sudo nginx -t
sudo systemctl reload nginx
