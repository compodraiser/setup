#!/bin/bash

# Update and Install Packages
sudo apt update
sudo apt install -y curl php nginx php-fpm mc

# Ask for Domain Name
read -p "Enter your domain name: " domain

# Install Certbot and Request SSL Certificate
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "$domain"

# Configure Nginx for PHP
sudo tee /etc/nginx/sites-available/$domain <<EOF
server {
    listen 80;
    server_name $domain;
    root /var/www/$domain;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Enable the Nginx Configuration
sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/$domain
sudo chown -R \$USER:\$USER /var/www/$domain
sudo systemctl restart nginx

echo "Setup Complete. Place your PHP files in /var/www/$domain"
