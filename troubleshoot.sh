#!/bin/bash

#############################################
# VibeSpeak Troubleshooting Script
# Checks and fixes common issues
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   VibeSpeak Troubleshooting            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking services...${NC}"
echo ""

# Check API service
echo -n "API Server: "
if systemctl is-active --quiet vibespeak-api; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Stopped${NC}"
    echo -e "${YELLOW}Starting API server...${NC}"
    systemctl start vibespeak-api
    sleep 2
fi

# Check WebSocket service
echo -n "WebSocket Server: "
if systemctl is-active --quiet vibespeak-websocket; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Stopped${NC}"
    echo -e "${YELLOW}Starting WebSocket server...${NC}"
    systemctl start vibespeak-websocket
    sleep 2
fi

# Check Nginx
echo -n "Nginx: "
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Stopped${NC}"
    echo -e "${YELLOW}Starting Nginx...${NC}"
    systemctl start nginx
fi

# Check MySQL
echo -n "MySQL: "
if systemctl is-active --quiet mysql; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Stopped${NC}"
    echo -e "${YELLOW}Starting MySQL...${NC}"
    systemctl start mysql
fi

echo ""
echo -e "${YELLOW}Checking ports...${NC}"
echo ""

# Check API port
echo -n "Port 8000 (API): "
if netstat -tlnp 2>/dev/null | grep -q ":8000"; then
    echo -e "${GREEN}Open${NC}"
    netstat -tlnp 2>/dev/null | grep ":8000"
else
    echo -e "${RED}Not listening${NC}"
    echo -e "${YELLOW}Checking API service logs...${NC}"
    journalctl -u vibespeak-api -n 20 --no-pager
fi

# Check WebSocket port
echo -n "Port 8080 (WebSocket): "
if netstat -tlnp 2>/dev/null | grep -q ":8080"; then
    echo -e "${GREEN}Open${NC}"
    netstat -tlnp 2>/dev/null | grep ":8080"
else
    echo -e "${RED}Not listening${NC}"
    echo -e "${YELLOW}Checking WebSocket service logs...${NC}"
    journalctl -u vibespeak-websocket -n 20 --no-pager
fi

# Check Nginx port
echo -n "Port 80 (Nginx): "
if netstat -tlnp 2>/dev/null | grep -q ":80"; then
    echo -e "${GREEN}Open${NC}"
else
    echo -e "${RED}Not listening${NC}"
fi

echo ""
echo -e "${YELLOW}Testing API endpoint...${NC}"
echo ""

# Test API health endpoint
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null)
if [ "$API_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ API is responding (HTTP $API_RESPONSE)${NC}"
    curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || echo ""
else
    echo -e "${RED}✗ API is not responding (HTTP $API_RESPONSE)${NC}"
    echo ""
    echo -e "${YELLOW}Trying to restart API service...${NC}"
    systemctl restart vibespeak-api
    sleep 3

    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null)
    if [ "$API_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ API is now responding${NC}"
    else
        echo -e "${RED}✗ API still not responding${NC}"
        echo -e "${YELLOW}Check logs: journalctl -u vibespeak-api -f${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}Checking firewall...${NC}"
echo ""

# Check UFW status
ufw status | grep -E "8000|8080|80|443"

echo ""
echo -e "${YELLOW}Quick fixes:${NC}"
echo ""

# Ensure firewall allows required ports
echo "1. Opening required ports in firewall..."
ufw allow 8000/tcp
ufw allow 8080/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Restart services
echo "2. Restarting all services..."
systemctl restart vibespeak-api
systemctl restart vibespeak-websocket
systemctl restart nginx

sleep 3

echo ""
echo -e "${GREEN}Services restarted!${NC}"
echo ""

# Final status check
echo -e "${YELLOW}Final status:${NC}"
echo ""

systemctl status vibespeak-api --no-pager -l | head -n 5
echo ""
systemctl status vibespeak-websocket --no-pager -l | head -n 5
echo ""

# Test API again
echo -e "${YELLOW}Final API test:${NC}"
curl -s http://localhost:8000/health 2>/dev/null || echo -e "${RED}API not responding${NC}"

echo ""
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  View API logs:        journalctl -u vibespeak-api -f"
echo "  View WebSocket logs:  journalctl -u vibespeak-websocket -f"
echo "  View Nginx logs:      tail -f /var/log/nginx/error.log"
echo "  Restart services:     systemctl restart vibespeak-api vibespeak-websocket nginx"
echo "  Check ports:          netstat -tlnp | grep -E '8000|8080|80'"
