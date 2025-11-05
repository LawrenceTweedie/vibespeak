#!/bin/bash

#############################################
# Fix Nginx for Vue Router (SPA)
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Fix Nginx for SPA Routing            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')

# Backup current config
echo -e "${YELLOW}Backing up current config...${NC}"
cp /etc/nginx/sites-available/vibespeak /etc/nginx/sites-available/vibespeak.bak.$(date +%Y%m%d_%H%M%S)

# Create new config
echo -e "${YELLOW}Creating new Nginx config...${NC}"

cat > /etc/nginx/sites-available/vibespeak << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    root /var/www/vibespeak/client/dist;
    index index.html;

    # Logs
    access_log /var/log/nginx/vibespeak-access.log;
    error_log /var/log/nginx/vibespeak-error.log;

    # Frontend - Vue SPA
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Downloads directory
    location /downloads/ {
        alias /var/www/vibespeak/downloads/;
        autoindex off;
        add_header Content-Disposition "attachment";
    }

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Test config
echo -e "${YELLOW}Testing Nginx config...${NC}"
if nginx -t; then
    echo -e "${GREEN}✓ Config is valid${NC}"

    # Reload Nginx
    echo -e "${YELLOW}Reloading Nginx...${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded${NC}"
else
    echo -e "${RED}✗ Config test failed${NC}"
    echo "Restoring backup..."
    mv /etc/nginx/sites-available/vibespeak.bak.$(date +%Y%m%d)* /etc/nginx/sites-available/vibespeak
    exit 1
fi

# Create downloads directory
echo -e "${YELLOW}Creating downloads directory...${NC}"
mkdir -p /var/www/vibespeak/downloads
chown -R www-data:www-data /var/www/vibespeak/downloads
chmod 755 /var/www/vibespeak/downloads

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Nginx Fixed!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Test URLs:${NC}"
echo "  Main: http://$SERVER_IP/"
echo "  Download: http://$SERVER_IP/download"
echo "  API: http://$SERVER_IP/api/health"
echo ""
echo "Downloads will be served from: /var/www/vibespeak/downloads/"
