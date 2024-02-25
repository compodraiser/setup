#!/bin/bash

echo "Updating and installing packages..."
sudo apt-get update && sudo apt-get install -y curl php nginx php-fpm mc certbot python3-certbot-nginx

read -p "Enter your domain name: " domain

# Check and stop Apache before making changes to avoid port conflicts
if systemctl is-active --quiet apache2; then
    echo "Stopping and disabling Apache..."
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    sudo apt-get purge -y apache2
    sudo apt-get autoremove -y
fi

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "Using PHP version: $PHP_VERSION"

echo "Creating Nginx configuration for $domain..."
cat <<EOF | sudo tee /etc/nginx/sites-available/$domain
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

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}

server {
    if (\$host = $domain) {
        return 301 https://\$host\$request_uri;
    }

    listen 80;
    server_name $domain;
    return 404;
}
EOF

echo "Enabling site configuration..."
sudo ln -sfn /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/$domain
sudo chown -R \$USER:\$USER /var/www/$domain

echo "Creating a PHP info file..."
echo "<?php phpinfo(); ?>" | sudo tee /var/www/$domain/index.php > /dev/null

echo "Testing Nginx configuration..."
sudo nginx -t

echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Obtaining SSL certificate..."
sudo certbot --nginx -d $domain --redirect --non-interactive --agree-tos -m your-email@example.com

echo "Setup Complete. Place your PHP files in /var/www/$domain"
