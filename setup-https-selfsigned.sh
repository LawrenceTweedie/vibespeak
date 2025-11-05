#!/bin/bash

#############################################
# Setup Self-Signed HTTPS Certificate
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
echo -e "${GREEN}║   Setup Self-Signed HTTPS              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${YELLOW}Creating self-signed certificate for $SERVER_IP...${NC}"

# Create directory for certificates
mkdir -p /etc/nginx/ssl

# Generate self-signed certificate valid for 1 year
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/vibespeak.key \
    -out /etc/nginx/ssl/vibespeak.crt \
    -subj "/C=RU/ST=State/L=City/O=VibeSpeak/CN=$SERVER_IP" \
    -addext "subjectAltName=IP:$SERVER_IP"

# Set permissions
chmod 600 /etc/nginx/ssl/vibespeak.key
chmod 644 /etc/nginx/ssl/vibespeak.crt

echo -e "${GREEN}✓ Certificate created${NC}"

# Update Nginx configuration
echo -e "${YELLOW}Updating Nginx configuration...${NC}"

# Backup current config
cp /etc/nginx/sites-available/vibespeak /etc/nginx/sites-available/vibespeak.bak.$(date +%Y%m%d_%H%M%S)

# Create new HTTPS config
cat > /etc/nginx/sites-available/vibespeak << EOF
# HTTP to HTTPS redirect
server {
    listen 80 default_server;
    server_name _;

    # Allow Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/vibespeak/client/dist;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2 default_server;
    server_name _;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/vibespeak.crt;
    ssl_certificate_key /etc/nginx/ssl/vibespeak.key;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Root and index
    root /var/www/vibespeak/client/dist;
    index index.html;

    # Logs
    access_log /var/log/nginx/vibespeak-access.log;
    error_log /var/log/nginx/vibespeak-error.log;

    # Frontend - Vue SPA
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
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # WebSocket proxy (for wss://)
    location /ws {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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

# Test Nginx configuration
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✓ Configuration is valid${NC}"

    # Reload Nginx
    echo -e "${YELLOW}Reloading Nginx...${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded${NC}"
else
    echo -e "${RED}✗ Configuration test failed${NC}"
    exit 1
fi

# Update client .env for WSS
echo -e "${YELLOW}Updating client configuration for HTTPS...${NC}"
cd /var/www/vibespeak/client

cat > .env << CLIENTENV
VITE_API_URL=https://$SERVER_IP/api
VITE_WS_URL=wss://$SERVER_IP/ws
CLIENTENV

# Rebuild client
echo "Rebuilding client..."
npm run build

# Reload Nginx again
systemctl reload nginx

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   HTTPS Setup Complete!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Access your application:${NC}"
echo "  HTTP:  http://$SERVER_IP (redirects to HTTPS)"
echo "  HTTPS: https://$SERVER_IP"
echo ""
echo -e "${YELLOW}⚠️ Browser Warning:${NC}"
echo "Your browser will show a security warning because this is"
echo "a self-signed certificate. This is normal and expected."
echo ""
echo -e "${YELLOW}To avoid the warning:${NC}"
echo "1. In browser, click 'Advanced' or 'Show Details'"
echo "2. Click 'Proceed to $SERVER_IP' or 'Accept Risk'"
echo "3. Or add certificate exception in browser settings"
echo ""
echo -e "${YELLOW}For production:${NC}"
echo "Get a free domain from services like:"
echo "  - DuckDNS (duckdns.org)"
echo "  - No-IP (noip.com)"
echo "  - Freenom (freenom.com)"
echo "Then use Let's Encrypt for trusted certificate."
