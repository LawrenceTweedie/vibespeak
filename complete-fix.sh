#!/bin/bash

#############################################
# Complete Fix for All VibeSpeak Issues
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
echo -e "${GREEN}║   Complete VibeSpeak Fix              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

cd /var/www/vibespeak

# Stop services
echo -e "${YELLOW}[1/7] Stopping services...${NC}"
systemctl stop vibespeak-api
systemctl stop vibespeak-websocket

# Create env.php
echo -e "${YELLOW}[2/7] Creating env.php loader...${NC}"
cat > server/config/env.php << 'ENVPHP'
<?php
/**
 * Simple .env file loader
 */

function loadEnv($path) {
    if (!file_exists($path)) {
        return;
    }

    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        // Skip comments
        if (strpos(trim($line), '#') === 0) {
            continue;
        }

        // Parse KEY=VALUE
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);

            // Remove quotes if present
            $value = trim($value, '"\'');

            // Set in $_ENV and putenv
            $_ENV[$key] = $value;
            putenv("$key=$value");
        }
    }
}

// Load .env file from server directory
$envPath = __DIR__ . '/../.env';
loadEnv($envPath);
ENVPHP

echo -e "${GREEN}✓ env.php created${NC}"

# Update database.php to load env.php
echo -e "${YELLOW}[3/7] Updating database.php...${NC}"
if ! grep -q "require_once.*env.php" server/config/database.php; then
    # Backup original
    cp server/config/database.php server/config/database.php.bak

    # Create new database.php
    cat > server/config/database.php << 'DBPHP'
<?php
/**
 * Database Configuration
 */

// Load environment variables
require_once __DIR__ . '/env.php';

return [
    'host' => getenv('DB_HOST') ?: 'localhost',
    'port' => getenv('DB_PORT') ?: 3306,
    'database' => getenv('DB_NAME') ?: 'vibespeak',
    'username' => getenv('DB_USER') ?: 'root',
    'password' => getenv('DB_PASS') ?: '',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
];
DBPHP
    echo -e "${GREEN}✓ database.php updated${NC}"
else
    echo -e "${GREEN}✓ database.php already loads env.php${NC}"
fi

# Fix WebSocket namespace issue
echo -e "${YELLOW}[4/7] Fixing WebSocket server...${NC}"

# Check if SignalingServer.php exists
if [ ! -f "server/websocket/SignalingServer.php" ]; then
    echo -e "${RED}✗ SignalingServer.php not found!${NC}"
    echo "Creating it..."

    # Ensure directory exists
    mkdir -p server/websocket

    # This file should already exist from git, but we'll create it if missing
    echo -e "${YELLOW}Please run: git pull to get the latest files${NC}"
fi

# Update websocket/server.php to use correct autoload
cat > server/websocket/server.php << 'WSPHP'
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use VibeSpeak\WebSocket\SignalingServer;

$config = include __DIR__ . '/../config/app.php';

$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new SignalingServer()
        )
    ),
    $config['websocket']['port'],
    $config['websocket']['host']
);

echo "WebSocket server started on {$config['websocket']['host']}:{$config['websocket']['port']}\n";

$server->run();
WSPHP

echo -e "${GREEN}✓ WebSocket server.php updated${NC}"

# Set permissions
echo -e "${YELLOW}[5/7] Setting permissions...${NC}"
chown -R www-data:www-data /var/www/vibespeak
chmod -R 755 /var/www/vibespeak
chmod 640 server/.env

# Test configuration
echo -e "${YELLOW}[6/7] Testing configuration...${NC}"

# Test env loading
echo "Testing env.php loading:"
php -r "
require_once '/var/www/vibespeak/server/config/env.php';
echo 'DB_HOST: ' . getenv('DB_HOST') . PHP_EOL;
echo 'DB_NAME: ' . getenv('DB_NAME') . PHP_EOL;
echo 'DB_USER: ' . getenv('DB_USER') . PHP_EOL;
echo 'DB_PASS: ' . (getenv('DB_PASS') ? 'SET' : 'EMPTY') . PHP_EOL;
"

# Test database connection
echo ""
echo "Testing database connection:"
DB_USER=$(grep DB_USER server/.env | cut -d'=' -f2 | tr -d ' "'"'"'')
DB_PASS=$(grep DB_PASS server/.env | cut -d'=' -f2 | tr -d ' "'"'"'')
DB_NAME=$(grep DB_NAME server/.env | cut -d'=' -f2 | tr -d ' "'"'"'')

if mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
fi

# Start services
echo ""
echo -e "${YELLOW}[7/7] Starting services...${NC}"
systemctl start vibespeak-api
sleep 2
systemctl start vibespeak-websocket
sleep 2

# Check status
echo ""
echo -e "${YELLOW}Service Status:${NC}"
echo -n "  API: "
if systemctl is-active --quiet vibespeak-api; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Failed${NC}"
    echo "Logs:"
    journalctl -u vibespeak-api -n 10 --no-pager
fi

echo -n "  WebSocket: "
if systemctl is-active --quiet vibespeak-websocket; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Failed${NC}"
    echo "Logs:"
    journalctl -u vibespeak-websocket -n 10 --no-pager
fi

# Test API
echo ""
echo -e "${YELLOW}Testing API...${NC}"
sleep 2

echo "1. Health check:"
curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/health

echo ""
echo "2. Registration test:"
TEST_USER="test_$(date +%s)"
curl -s -X POST http://localhost:8000/users/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TEST_USER\",\"email\":\"$TEST_USER@test.com\",\"password\":\"testpass123\"}" | python3 -m json.tool 2>/dev/null

echo ""
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Fix Complete!                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}If API still shows database errors, check:${NC}"
echo "  1. cat /var/www/vibespeak/server/.env"
echo "  2. php -r 'require \"/var/www/vibespeak/server/config/env.php\"; echo getenv(\"DB_USER\");'"
echo "  3. journalctl -u vibespeak-api -f"
