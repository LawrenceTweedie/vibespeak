#!/bin/bash

#############################################
# Install Wine32 for Windows Builds
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
echo -e "${GREEN}║   Install Wine32 for Windows Builds    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}This will install Wine32 for building Windows .exe files${NC}"
echo "Approximately 300-500 MB will be downloaded."
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Enable 32-bit architecture
echo -e "${YELLOW}[1/3] Enabling i386 architecture...${NC}"
dpkg --add-architecture i386

# Update package list
echo -e "${YELLOW}[2/3] Updating package lists...${NC}"
apt-get update

# Install wine32
echo -e "${YELLOW}[3/3] Installing wine32...${NC}"
echo "This may take a few minutes..."
apt-get install -y wine32:i386 wine64

echo ""
echo -e "${GREEN}✓ Wine32 installed successfully!${NC}"

# Test wine
echo ""
echo -e "${YELLOW}Testing Wine installation...${NC}"
wine --version

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "You can now build Windows applications:"
echo "  cd /var/www/vibespeak"
echo "  ./build-on-server.sh"
