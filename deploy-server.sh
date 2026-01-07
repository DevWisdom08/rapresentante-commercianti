#!/bin/bash
#
# RAPRESENTANTE COMMERCIANTI - SERVER DEPLOYMENT SCRIPT
# Run this on your DigitalOcean Ubuntu server
#

set -e  # Exit on error

echo "========================================="
echo "RAPRESENTANTE COMMERCIANTI - DEPLOYMENT"
echo "========================================="
echo ""

# Update system
echo "📦 Updating system..."
apt update && apt upgrade -y

# Install Nginx
echo "📦 Installing Nginx..."
apt install nginx -y

# Install PHP 8.2
echo "📦 Installing PHP 8.2..."
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update
apt install php8.2-fpm php8.2-sqlite3 php8.2-mbstring php8.2-xml php8.2-bcmath php8.2-curl php8.2-zip php8.2-cli -y

# Install Composer
echo "📦 Installing Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Install Git
echo "📦 Installing Git..."
apt install git -y

# Clone repository
echo "📦 Cloning repository..."
cd /var/www
git clone https://github.com/DevWisdom08/rapresentante-commercianti.git
cd rapresentante-commercianti/backend

# Install Laravel dependencies
echo "📦 Installing Laravel dependencies..."
composer install --no-dev --optimize-autoloader

# Setup environment
echo "📦 Configuring Laravel..."
cp env.example.txt .env

# Generate keys
php artisan key:generate --force

# Create SQLite database
touch database/database.sqlite

# Set permissions
chown -R www-data:www-data /var/www/rapresentante-commercianti
chmod -R 775 /var/www/rapresentante-commercianti/backend/storage
chmod -R 775 /var/www/rapresentante-commercianti/backend/bootstrap/cache

# Run migrations
echo "📦 Creating database..."
php artisan migrate --force
php artisan db:seed --force

# Configure Nginx
echo "📦 Configuring Nginx..."
cat > /etc/nginx/sites-available/rapresentante << 'EOF'
server {
    listen 80;
    server_name 64.23.151.140;
    root /var/www/rapresentante-commercianti/backend/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/rapresentante /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t
systemctl restart nginx
systemctl restart php8.2-fpm

echo ""
echo "========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "🌐 Your API is now available at:"
echo "   http://64.23.151.140/api/health"
echo ""
echo "📧 Test credentials:"
echo "   Cliente: mario.rossi@test.it / Password123!"
echo "   Esercente: panificio@test.it / Password123!"
echo "   Admin: admin@rapresentante.it / Password123!"
echo ""
echo "========================================="

