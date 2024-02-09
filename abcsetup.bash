#!/bin/bash

# Update and Install Packages
sudo apt update
sudo apt install -y curl php nginx php-fpm mc

# Ask for Domain Name
read -p "Enter your domain name: " domain

# Install Certbot and Request SSL Certificate
sudo apt install -y certbot python3-certbot-nginx
# Preemptively create a server block to avoid certbot creating a default one
sudo tee /etc/nginx/sites-available/$domain <<EOF
server {
    listen 443 ssl; # managed by Certbot
    server_name $domain;
    root /var/www/$domain;
    index index.php index.html index.htm;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php\$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}

server {
    if (\$host = $domain) {
        return 301 https://\$host\$request_uri;
    } # managed by Certbot

    listen 80;
    server_name $domain;
    return 404; # managed by Certbot
}
EOF

# Enable the Nginx Configuration
sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/$domain
sudo chown -R \$USER:\$USER /var/www/$domain
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

sudo systemctl reload nginx

# Obtain SSL Certificate and Modify Nginx Configuration for HTTPS
sudo certbot --nginx -d $domain --redirect --non-interactive --agree-tos -m abcteamcpa@yandex.ru

# Reload Nginx to apply changes
sudo systemctl reload nginx

# Stop Apache Service
sudo systemctl stop apache2

# Disable Apache from Starting on Boot
sudo systemctl disable apache2

# Uninstall Apache
sudo apt-get purge -y apache2
sudo apt-get autoremove -y

echo "Setup Complete. Place your PHP files in /var/www/$domain"
