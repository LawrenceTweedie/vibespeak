#!/bin/bash

#############################################
# Quick Fix Script for VibeSpeak
# Restarts services and checks status
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}Quick Fix - Restarting all services...${NC}"
echo ""

# Open firewall ports
echo "Opening firewall ports..."
ufw allow 8000/tcp
ufw allow 8080/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Restart MySQL
echo "Restarting MySQL..."
systemctl restart mysql

# Restart API
echo "Restarting API server..."
systemctl restart vibespeak-api
sleep 2

# Restart WebSocket
echo "Restarting WebSocket server..."
systemctl restart vibespeak-websocket
sleep 2

# Restart Nginx
echo "Restarting Nginx..."
systemctl restart nginx

echo ""
echo -e "${GREEN}All services restarted!${NC}"
echo ""

# Check status
echo -e "${YELLOW}Status:${NC}"
echo -n "  API Server: "
systemctl is-active vibespeak-api && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"
echo -n "  WebSocket:  "
systemctl is-active vibespeak-websocket && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"
echo -n "  Nginx:      "
systemctl is-active nginx && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"
echo -n "  MySQL:      "
systemctl is-active mysql && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}"

echo ""
echo -e "${YELLOW}Testing API...${NC}"
sleep 2

API_TEST=$(curl -s http://localhost:8000/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API is responding${NC}"
    echo "$API_TEST"
else
    echo -e "${RED}✗ API is not responding${NC}"
    echo -e "${YELLOW}Check logs: journalctl -u vibespeak-api -f${NC}"
fi

echo ""
echo -e "${YELLOW}Ports:${NC}"
netstat -tlnp 2>/dev/null | grep -E ":80|:8000|:8080" || ss -tlnp | grep -E ":80|:8000|:8080"
