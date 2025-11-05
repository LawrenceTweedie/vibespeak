#!/bin/bash

#############################################
# Fix VibeSpeak Services
# Installs dependencies and fixes common issues
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
echo -e "${GREEN}║   VibeSpeak Services Fix              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

cd /var/www/vibespeak/server

echo -e "${YELLOW}[1/5] Stopping services...${NC}"
systemctl stop vibespeak-websocket
systemctl stop vibespeak-api

echo -e "${YELLOW}[2/5] Installing Composer dependencies...${NC}"
if [ -f "composer.json" ]; then
    composer install --no-dev --optimize-autoloader
    echo -e "${GREEN}✓ Composer dependencies installed${NC}"
else
    echo -e "${RED}✗ composer.json not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}[3/5] Checking vendor directory...${NC}"
if [ -d "vendor" ]; then
    echo -e "${GREEN}✓ vendor/ directory exists${NC}"
    ls -la vendor/ | head -n 10
else
    echo -e "${RED}✗ vendor/ directory missing!${NC}"
    exit 1
fi

echo -e "${YELLOW}[4/5] Checking autoload files...${NC}"
if [ -f "vendor/autoload.php" ]; then
    echo -e "${GREEN}✓ autoload.php exists${NC}"
else
    echo -e "${RED}✗ autoload.php missing!${NC}"
    exit 1
fi

echo -e "${YELLOW}[5/5] Setting permissions...${NC}"
chown -R www-data:www-data /var/www/vibespeak
chmod -R 755 /var/www/vibespeak

echo ""
echo -e "${GREEN}Starting services...${NC}"
systemctl start vibespeak-api
sleep 2
systemctl start vibespeak-websocket
sleep 2

echo ""
echo -e "${YELLOW}Service Status:${NC}"
echo -n "  API: "
systemctl is-active vibespeak-api && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Failed${NC}"
echo -n "  WebSocket: "
systemctl is-active vibespeak-websocket && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Failed${NC}"

echo ""
echo -e "${YELLOW}Checking for errors...${NC}"
echo ""
echo "API Service (last 10 lines):"
journalctl -u vibespeak-api -n 10 --no-pager
echo ""
echo "WebSocket Service (last 10 lines):"
journalctl -u vibespeak-websocket -n 10 --no-pager

echo ""
echo -e "${YELLOW}Testing API...${NC}"
sleep 2
curl -s http://localhost:8000/health || echo -e "${RED}API not responding${NC}"

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo -e "${YELLOW}If issues persist, check logs:${NC}"
echo "  journalctl -u vibespeak-api -f"
echo "  journalctl -u vibespeak-websocket -f"
