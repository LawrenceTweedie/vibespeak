#!/bin/bash

#############################################
# VibeSpeak Auto-Install Script
# For Ubuntu 24.04 LTS
# Server IP: 79.174.77.181
#############################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="79.174.77.181"
DB_NAME="vibespeak"
DB_USER="vibespeak_user"
DB_PASS=$(openssl rand -base64 12)
DB_ROOT_PASS=""  # Will be prompted
DOMAIN=""  # Optional: set your domain for SSL

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   VibeSpeak Auto-Install Script       ║${NC}"
echo -e "${GREEN}║   Ubuntu 24.04 LTS                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}This script will install:${NC}"
echo "  - PHP 8.3"
echo "  - MySQL 8.0"
echo "  - Node.js 20"
echo "  - Nginx"
echo "  - Composer"
echo "  - All required dependencies"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Prompt for MySQL root password
echo ""
read -sp "Enter MySQL root password (will be created): " DB_ROOT_PASS
echo ""
read -sp "Confirm MySQL root password: " DB_ROOT_PASS_CONFIRM
echo ""

if [ "$DB_ROOT_PASS" != "$DB_ROOT_PASS_CONFIRM" ]; then
    echo -e "${RED}Passwords do not match!${NC}"
    exit 1
fi

# Optional: Domain configuration
echo ""
read -p "Do you have a domain name? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter your domain (e.g., vibespeak.com): " DOMAIN
    read -p "Enter API subdomain (default: api.${DOMAIN}): " API_DOMAIN
    API_DOMAIN=${API_DOMAIN:-api.${DOMAIN}}
    read -p "Enter WebSocket subdomain (default: ws.${DOMAIN}): " WS_DOMAIN
    WS_DOMAIN=${WS_DOMAIN:-ws.${DOMAIN}}
fi

echo ""
echo -e "${GREEN}Starting installation...${NC}"
echo ""

#############################################
# 1. Update System
#############################################
echo -e "${YELLOW}[1/12] Updating system...${NC}"
apt-get update -qq
apt-get upgrade -y -qq

#############################################
# 2. Install Basic Tools
#############################################
echo -e "${YELLOW}[2/12] Installing basic tools...${NC}"
apt-get install -y -qq \
    software-properties-common \
    curl \
    wget \
    git \
    unzip \
    supervisor \
    ufw \
    certbot \
    python3-certbot-nginx

#############################################
# 3. Install PHP 8.3
#############################################
echo -e "${YELLOW}[3/12] Installing PHP 8.3...${NC}"
add-apt-repository -y ppa:ondrej/php
apt-get update -qq
apt-get install -y -qq \
    php8.3 \
    php8.3-fpm \
    php8.3-mysql \
    php8.3-cli \
    php8.3-curl \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-json \
    php8.3-opcache

#############################################
# 4. Install Composer
#############################################
echo -e "${YELLOW}[4/12] Installing Composer...${NC}"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#############################################
# 5. Install MySQL
#############################################
echo -e "${YELLOW}[5/12] Installing MySQL...${NC}"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
apt-get install -y -qq mysql-server

# Secure MySQL installation
mysql -uroot -p"$DB_ROOT_PASS" <<MYSQL_SCRIPT
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

#############################################
# 6. Install Node.js 20
#############################################
echo -e "${YELLOW}[6/12] Installing Node.js 20...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -qq nodejs

#############################################
# 7. Install Nginx
#############################################
echo -e "${YELLOW}[7/12] Installing Nginx...${NC}"
apt-get install -y -qq nginx

#############################################
# 8. Clone/Setup VibeSpeak
#############################################
echo -e "${YELLOW}[8/12] Setting up VibeSpeak...${NC}"
cd /var/www

# If VibeSpeak already exists, backup and remove
if [ -d "vibespeak" ]; then
    mv vibespeak vibespeak.backup.$(date +%Y%m%d_%H%M%S)
fi

# Clone repository or copy files
# Note: Replace with your actual repository URL
# git clone https://github.com/yourusername/vibespeak.git vibespeak

# For now, assume files are uploaded manually to /var/www/vibespeak
# Create directory if it doesn't exist
mkdir -p vibespeak
cd vibespeak

# Set permissions
chown -R www-data:www-data /var/www/vibespeak
chmod -R 755 /var/www/vibespeak

#############################################
# 9. Setup Database
#############################################
echo -e "${YELLOW}[9/12] Setting up database...${NC}"

# Create database and user
mysql -uroot -p"$DB_ROOT_PASS" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Import schema (if schema file exists)
if [ -f "/var/www/vibespeak/server/database/schema.sql" ]; then
    mysql -uroot -p"$DB_ROOT_PASS" $DB_NAME < /var/www/vibespeak/server/database/schema.sql
    echo -e "${GREEN}Database schema imported successfully${NC}"
fi

#############################################
# 10. Configure VibeSpeak Backend
#############################################
echo -e "${YELLOW}[10/12] Configuring backend...${NC}"
cd /var/www/vibespeak/server

# Install PHP dependencies
if [ -f "composer.json" ]; then
    composer install --no-dev --optimize-autoloader
fi

# Create .env file
cat > .env <<EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASS

# WebSocket Configuration
WS_HOST=0.0.0.0
WS_PORT=8080

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
EOF

chmod 640 .env
chown www-data:www-data .env

#############################################
# 11. Configure Frontend
#############################################
echo -e "${YELLOW}[11/12] Building frontend...${NC}"
cd /var/www/vibespeak/client

# Install dependencies
if [ -f "package.json" ]; then
    npm install --silent

    # Create .env file
    if [ -n "$DOMAIN" ]; then
        cat > .env <<EOF
VITE_API_URL=https://$API_DOMAIN
VITE_WS_URL=wss://$WS_DOMAIN
EOF
    else
        cat > .env <<EOF
VITE_API_URL=http://$SERVER_IP:8000
VITE_WS_URL=ws://$SERVER_IP:8080
EOF
    fi

    # Build production version
    npm run build
    echo -e "${GREEN}Frontend built successfully${NC}"
fi

#############################################
# 12. Configure Services
#############################################
echo -e "${YELLOW}[12/12] Configuring services...${NC}"

# Create systemd service for WebSocket server
cat > /etc/systemd/system/vibespeak-websocket.service <<EOF
[Unit]
Description=VibeSpeak WebSocket Server
After=network.target mysql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/vibespeak/server
ExecStart=/usr/bin/php /var/www/vibespeak/server/websocket/server.php
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for API (using PHP built-in server for dev/testing)
cat > /etc/systemd/system/vibespeak-api.service <<EOF
[Unit]
Description=VibeSpeak API Server
After=network.target mysql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/vibespeak/server/api
ExecStart=/usr/bin/php -S 0.0.0.0:8000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable and start services
systemctl enable vibespeak-websocket
systemctl enable vibespeak-api
systemctl start vibespeak-websocket
systemctl start vibespeak-api

# Configure Nginx
if [ -n "$DOMAIN" ]; then
    # Configuration with domain
    cat > /etc/nginx/sites-available/vibespeak <<EOF
# Frontend
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root /var/www/vibespeak/client/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}

# API
server {
    listen 80;
    server_name $API_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# WebSocket
server {
    listen 80;
    server_name $WS_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
else
    # Configuration with IP only
    cat > /etc/nginx/sites-available/vibespeak <<EOF
server {
    listen 80 default_server;
    server_name $SERVER_IP _;
    root /var/www/vibespeak/client/dist;
    index index.html;

    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}

# WebSocket on port 8080 (direct access)
# Users will connect to ws://$SERVER_IP:8080
EOF
fi

# Enable site
ln -sf /etc/nginx/sites-available/vibespeak /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

#############################################
# Configure Firewall
#############################################
echo -e "${YELLOW}Configuring firewall...${NC}"
ufw --force enable
ufw allow 22/tcp  # SSH
ufw allow 80/tcp  # HTTP
ufw allow 443/tcp # HTTPS
ufw allow 8080/tcp # WebSocket

#############################################
# SSL Certificate (if domain provided)
#############################################
if [ -n "$DOMAIN" ]; then
    echo -e "${YELLOW}Setting up SSL certificates...${NC}"
    read -p "Install SSL certificates with Let's Encrypt? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        certbot --nginx -d $DOMAIN -d www.$DOMAIN -d $API_DOMAIN -d $WS_DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

        # Update frontend .env with HTTPS
        cd /var/www/vibespeak/client
        cat > .env <<EOF
VITE_API_URL=https://$API_DOMAIN
VITE_WS_URL=wss://$WS_DOMAIN
EOF
        npm run build
    fi
fi

#############################################
# Save Credentials
#############################################
cat > /root/vibespeak-credentials.txt <<EOF
VibeSpeak Installation Credentials
===================================

Date: $(date)
Server IP: $SERVER_IP

MySQL Root Password: $DB_ROOT_PASS
Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS

$(if [ -n "$DOMAIN" ]; then
echo "Domain: $DOMAIN"
echo "API Domain: $API_DOMAIN"
echo "WebSocket Domain: $WS_DOMAIN"
fi)

Application URLs:
$(if [ -n "$DOMAIN" ]; then
echo "  Frontend: https://$DOMAIN"
echo "  API: https://$API_DOMAIN"
echo "  WebSocket: wss://$WS_DOMAIN"
else
echo "  Frontend: http://$SERVER_IP"
echo "  API: http://$SERVER_IP:8000"
echo "  WebSocket: ws://$SERVER_IP:8080"
fi)

Demo Account:
  Username: demo
  Password: password

Service Status Commands:
  systemctl status vibespeak-websocket
  systemctl status vibespeak-api
  systemctl status nginx
  systemctl status mysql

Logs:
  journalctl -u vibespeak-websocket -f
  journalctl -u vibespeak-api -f
  tail -f /var/log/nginx/error.log

IMPORTANT: Save this file and delete it after noting credentials!
EOF

chmod 600 /root/vibespeak-credentials.txt

#############################################
# Final Status Check
#############################################
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Service Status:${NC}"
echo -n "  WebSocket Server: "
systemctl is-active vibespeak-websocket && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"
echo -n "  API Server: "
systemctl is-active vibespeak-api && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"
echo -n "  Nginx: "
systemctl is-active nginx && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"
echo -n "  MySQL: "
systemctl is-active mysql && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"

echo ""
echo -e "${YELLOW}Access your application:${NC}"
if [ -n "$DOMAIN" ]; then
    echo -e "  Frontend: ${GREEN}https://$DOMAIN${NC}"
    echo -e "  API: ${GREEN}https://$API_DOMAIN${NC}"
else
    echo -e "  Frontend: ${GREEN}http://$SERVER_IP${NC}"
    echo -e "  API: ${GREEN}http://$SERVER_IP:8000${NC}"
fi

echo ""
echo -e "${YELLOW}Credentials saved to: ${GREEN}/root/vibespeak-credentials.txt${NC}"
echo -e "${RED}Please save the credentials and delete this file!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review credentials: cat /root/vibespeak-credentials.txt"
echo "  2. Test the application in your browser"
echo "  3. Check logs if needed: journalctl -u vibespeak-websocket -f"
echo "  4. Configure domain DNS if not done already"
echo ""
echo -e "${GREEN}Installation completed successfully!${NC}"
