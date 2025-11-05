#!/bin/bash

#############################################
# Fix VibeSpeak Database Connection
# Recreates database and fixes .env
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
echo -e "${GREEN}║   VibeSpeak Database Fix              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
DB_NAME="vibespeak"
DB_USER="vibespeak_user"
DB_PASS=$(openssl rand -base64 12)

echo -e "${YELLOW}Database Configuration:${NC}"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASS"
echo ""

# Prompt for MySQL root password
read -sp "Enter MySQL root password: " DB_ROOT_PASS
echo ""

# Test MySQL connection
echo -e "${YELLOW}Testing MySQL connection...${NC}"
if ! mysql -uroot -p"$DB_ROOT_PASS" -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "${RED}Failed to connect to MySQL!${NC}"
    echo "Please check your MySQL root password"
    exit 1
fi
echo -e "${GREEN}✓ MySQL connection successful${NC}"

# Create database and user
echo -e "${YELLOW}Creating database and user...${NC}"
mysql -uroot -p"$DB_ROOT_PASS" <<MYSQL_SCRIPT
-- Drop existing database and user if exists
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS '$DB_USER'@'localhost';

-- Create database
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';

-- Grant privileges
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo -e "${GREEN}✓ Database and user created${NC}"

# Import schema
echo -e "${YELLOW}Importing database schema...${NC}"
if [ -f "/var/www/vibespeak/server/database/schema.sql" ]; then
    mysql -uroot -p"$DB_ROOT_PASS" $DB_NAME < /var/www/vibespeak/server/database/schema.sql
    echo -e "${GREEN}✓ Schema imported successfully${NC}"
else
    echo -e "${RED}✗ Schema file not found!${NC}"
    echo "Location: /var/www/vibespeak/server/database/schema.sql"
fi

# Update .env file
echo -e "${YELLOW}Updating .env file...${NC}"
cd /var/www/vibespeak/server

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

echo -e "${GREEN}✓ .env file updated${NC}"

# Verify .env file
echo ""
echo -e "${YELLOW}.env file contents:${NC}"
cat .env
echo ""

# Test database connection with new credentials
echo -e "${YELLOW}Testing database connection with new credentials...${NC}"
if mysql -u"$DB_USER" -p"$DB_PASS" $DB_NAME -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
    exit 1
fi

# Verify tables were created
echo -e "${YELLOW}Verifying tables...${NC}"
TABLES=$(mysql -u"$DB_USER" -p"$DB_PASS" $DB_NAME -e "SHOW TABLES;" -s)
if [ -n "$TABLES" ]; then
    echo -e "${GREEN}✓ Tables found:${NC}"
    echo "$TABLES"
else
    echo -e "${RED}✗ No tables found${NC}"
fi

# Restart services
echo ""
echo -e "${YELLOW}Restarting services...${NC}"
systemctl restart vibespeak-api
systemctl restart vibespeak-websocket
sleep 2

# Check service status
echo ""
echo -e "${YELLOW}Service Status:${NC}"
echo -n "  API: "
systemctl is-active vibespeak-api && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Failed${NC}"
echo -n "  WebSocket: "
systemctl is-active vibespeak-websocket && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Failed${NC}"

# Test API
echo ""
echo -e "${YELLOW}Testing API...${NC}"
sleep 2
API_RESPONSE=$(curl -s http://localhost:8000/health)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API is responding${NC}"
    echo "$API_RESPONSE"
else
    echo -e "${RED}✗ API not responding${NC}"
fi

# Test registration endpoint
echo ""
echo -e "${YELLOW}Testing user registration...${NC}"
TEST_USER="test_$(date +%s)"
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8000/users/register \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_USER\",\"email\":\"$TEST_USER@test.com\",\"password\":\"testpass123\"}")

if echo "$REGISTER_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✓ Registration endpoint working${NC}"
    echo "$REGISTER_RESPONSE"
else
    echo -e "${RED}✗ Registration failed${NC}"
    echo "$REGISTER_RESPONSE"
fi

# Save credentials
echo ""
echo -e "${YELLOW}Saving credentials...${NC}"
cat > /root/vibespeak-db-credentials.txt <<EOF
VibeSpeak Database Credentials
==============================
Created: $(date)

MySQL Root Password: $DB_ROOT_PASS
Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS

Server IP: $(hostname -I | awk '{print $1}')

.env file location: /var/www/vibespeak/server/.env

Test commands:
  mysql -u$DB_USER -p$DB_PASS $DB_NAME
  systemctl status vibespeak-api
  journalctl -u vibespeak-api -f

IMPORTANT: Save this information and delete this file!
EOF

chmod 600 /root/vibespeak-db-credentials.txt

echo -e "${GREEN}✓ Credentials saved to: /root/vibespeak-db-credentials.txt${NC}"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Database Setup Complete!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test registration in browser"
echo "  2. View credentials: cat /root/vibespeak-db-credentials.txt"
echo "  3. Check API logs: journalctl -u vibespeak-api -f"
echo ""
