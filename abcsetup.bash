#!/bin/bash

# Update and Install Packages
echo "Updating packages and installing required software..."
sudo apt update
sudo apt install -y curl php nginx php-fpm mc certbot python3-certbot-nginx

# Ask for Domain Name
read -p "Enter your domain name: " domain

# Install Certbot and Obtain SSL Certificate First
echo "Installing Certbot and obtaining SSL certificate for $domain..."
sudo certbot certonly --webroot -w /var/www/html -d "$domain" --non-interactive --agree-tos -m abcteamcpa@yandex.ru

# After SSL certificate is obtained, configure Nginx
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "Configuring Nginx for $domain with PHP version $PHP_VERSION..."
sudo bash -c "cat > /etc/nginx/sites-available/$domain <<'EOF'
server {
    listen 443 ssl;
    server_name $domain;
    root /var/www/$domain;
    index index.php index.html index.htm;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }
}

server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}
EOF"

# Enable the Nginx Configuration
echo "Enabling site and reloading Nginx..."
sudo ln -sfn /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/$domain
sudo chown -R \$USER:\$USER /var/www/$domain

# Create a PHP info file for testing
echo "<?php phpinfo(); ?>" | sudo tee /var/www/$domain/index.php > /dev/null

# Test Nginx configuration and reload
sudo nginx -t
sudo systemctl reload nginx

echo "Setup complete. Place your PHP files in /var/www/$domain"
