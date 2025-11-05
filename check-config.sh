#!/bin/bash

#############################################
# Check VibeSpeak Configuration
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Configuration Check                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

cd /var/www/vibespeak

echo -e "${YELLOW}1. Checking .env file...${NC}"
if [ -f "server/.env" ]; then
    echo -e "${GREEN}✓ .env file exists${NC}"
    echo "Contents:"
    cat server/.env
    echo ""
else
    echo -e "${RED}✗ .env file not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}2. Checking env.php loader...${NC}"
if [ -f "server/config/env.php" ]; then
    echo -e "${GREEN}✓ env.php exists${NC}"
else
    echo -e "${RED}✗ env.php not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}3. Checking database.php...${NC}"
if grep -q "require_once.*env.php" server/config/database.php; then
    echo -e "${GREEN}✓ database.php loads env.php${NC}"
else
    echo -e "${RED}✗ database.php doesn't load env.php!${NC}"
    exit 1
fi

echo -e "${YELLOW}4. Testing PHP env loading...${NC}"
php -r "
require_once '/var/www/vibespeak/server/config/env.php';
echo 'DB_HOST: ' . getenv('DB_HOST') . PHP_EOL;
echo 'DB_NAME: ' . getenv('DB_NAME') . PHP_EOL;
echo 'DB_USER: ' . getenv('DB_USER') . PHP_EOL;
echo 'DB_PASS: ' . (getenv('DB_PASS') ? '***' : 'EMPTY') . PHP_EOL;
"

echo ""
echo -e "${YELLOW}5. Testing database connection...${NC}"
DB_HOST=$(grep DB_HOST server/.env | cut -d'=' -f2 | tr -d ' "'"'"'')
DB_NAME=$(grep DB_NAME server/.env | cut -d'=' -f2 | tr -d ' "'"'"'')
DB_USER=$(grep DB_USER server/.env | cut -d'=' -f2 | tr -d ' "'"'"'')
DB_PASS=$(grep DB_PASS server/.env | cut -d'=' -f2 | tr -d ' "'"'"'')

echo "Connecting as: $DB_USER@$DB_HOST/$DB_NAME"

if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
    echo "Try manually: mysql -h$DB_HOST -u$DB_USER -p$DB_PASS $DB_NAME"
    exit 1
fi

echo ""
echo -e "${GREEN}All checks passed!${NC}"
