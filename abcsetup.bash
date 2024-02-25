#!/bin/bash

# Update and Install Packages
echo "Updating packages and installing required software..."
sudo apt update
sudo apt install -y curl php nginx php-fpm mc certbot python3-certbot-nginx

# Ask for Domain Name
read -p "Enter your domain name: " domain

# Initial Nginx Configuration (HTTP only)
echo "Configuring Nginx for $domain..."
sudo bash -c "cat > /etc/nginx/sites-available/$domain <<EOF
server {
    listen 80;
    server_name $domain;
    root /var/www/$domain;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF"

# Enable the Nginx Configuration
sudo ln -sfn /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/$domain
echo "<?php phpinfo(); ?>" | sudo tee /var/www/$domain/index.php > /dev/null
sudo chown -R www-data:www-data /var/www/$domain
sudo nginx -t && sudo systemctl reload nginx

# Obtain SSL Certificate
echo "Obtaining SSL certificate for $domain..."
sudo certbot --nginx -d "$domain" --non-interactive --agree-tos -m your-email@example.com --redirect

echo "Adjusting Nginx configuration for $domain..."
sudo sed -i 's|try_files  / =404;|try_files $uri $uri/ =404;|' /etc/nginx/sites-available/$domain

# Reload Nginx to apply SSL configuration
sudo nginx -t && sudo systemctl reload nginx

echo "Setup complete. Your site should be available over HTTPS."
