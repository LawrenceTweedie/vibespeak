#!/bin/bash

#############################################
# Deploy VibeSpeak to Server
# This script uploads files to the server
#############################################

SERVER_IP="79.174.77.181"
SERVER_USER="root"  # Change if using different user
REMOTE_PATH="/var/www/vibespeak"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Deploy VibeSpeak to Server          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "install.sh" ]; then
    echo -e "${RED}Error: Must run from VibeSpeak root directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Deploying to: ${SERVER_USER}@${SERVER_IP}${NC}"
echo ""

# Check SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! ssh -o ConnectTimeout=5 ${SERVER_USER}@${SERVER_IP} "echo 'Connection successful'"; then
    echo -e "${RED}Failed to connect to server${NC}"
    echo "Please ensure:"
    echo "  1. Server is running"
    echo "  2. SSH is enabled"
    echo "  3. You have SSH key or password access"
    exit 1
fi

echo -e "${GREEN}Connected successfully!${NC}"
echo ""

# Create remote directory
echo -e "${YELLOW}Creating remote directory...${NC}"
ssh ${SERVER_USER}@${SERVER_IP} "mkdir -p ${REMOTE_PATH}"

# Upload files
echo -e "${YELLOW}Uploading files...${NC}"
rsync -avz --progress \
    --exclude 'node_modules' \
    --exclude 'vendor' \
    --exclude 'dist' \
    --exclude '.git' \
    --exclude '.env' \
    --exclude '*.log' \
    ./ ${SERVER_USER}@${SERVER_IP}:${REMOTE_PATH}/

echo ""
echo -e "${GREEN}Files uploaded successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. SSH into the server: ssh ${SERVER_USER}@${SERVER_IP}"
echo "  2. Navigate to: cd ${REMOTE_PATH}"
echo "  3. Make install script executable: chmod +x install.sh"
echo "  4. Run installation: sudo ./install.sh"
echo ""
echo -e "${YELLOW}Or run directly:${NC}"
echo -e "  ssh ${SERVER_USER}@${SERVER_IP} 'cd ${REMOTE_PATH} && chmod +x install.sh && sudo ./install.sh'"
