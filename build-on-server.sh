#!/bin/bash

#############################################
# Build Desktop Apps on Server
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VibeSpeak Desktop Build (Server)     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Running as root. This is not recommended for npm builds.${NC}"
    echo "Consider running as regular user with sudo only for final steps."
    echo ""
fi

cd /var/www/vibespeak

# Step 1: Build client
echo -e "${YELLOW}[1/5] Building Vue3 client...${NC}"
cd client

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing client dependencies..."
    npm install
fi

# Build client
echo "Building production client..."
npm run build

echo -e "${GREEN}✓ Client built${NC}"
cd ..

# Step 2: Install desktop dependencies
echo -e "${YELLOW}[2/5] Installing desktop dependencies...${NC}"
cd desktop

if [ ! -d "node_modules" ]; then
    echo "Installing desktop dependencies..."
    npm install
fi

echo -e "${GREEN}✓ Desktop dependencies installed${NC}"

# Step 3: Build for Windows
echo -e "${YELLOW}[3/5] Building for Windows...${NC}"
echo "This may take 5-10 minutes..."

npm run build:win || {
    echo -e "${RED}Windows build failed. This is normal if wine is not installed.${NC}"
    echo "Install wine: apt-get install wine64"
}

# Step 4: Build for Linux
echo -e "${YELLOW}[4/5] Building for Linux...${NC}"
npm run build:linux

echo -e "${GREEN}✓ Linux builds complete${NC}"

# Step 5: Copy to downloads directory
echo -e "${YELLOW}[5/5] Copying files to downloads directory...${NC}"
cd ..

# Create downloads directory
mkdir -p /var/www/vibespeak/downloads

# Copy built files
if [ -d "desktop/dist" ]; then
    cp desktop/dist/*.exe /var/www/vibespeak/downloads/ 2>/dev/null || echo "No .exe files"
    cp desktop/dist/*.AppImage /var/www/vibespeak/downloads/ 2>/dev/null || echo "No AppImage files"
    cp desktop/dist/*.deb /var/www/vibespeak/downloads/ 2>/dev/null || echo "No .deb files"

    # Rename files to standard names
    cd /var/www/vibespeak/downloads

    # Find and rename Windows installer
    if ls *.exe 1> /dev/null 2>&1; then
        mv *.exe VibeSpeak-Setup.exe 2>/dev/null || true
    fi

    # Find and rename AppImage
    if ls *.AppImage 1> /dev/null 2>&1; then
        chmod +x *.AppImage
        mv *.AppImage VibeSpeak.AppImage 2>/dev/null || true
    fi

    # Find and rename .deb
    if ls *.deb 1> /dev/null 2>&1; then
        mv *.deb vibespeak.deb 2>/dev/null || true
    fi

    # Set permissions
    chown -R www-data:www-data /var/www/vibespeak/downloads
    chmod 644 /var/www/vibespeak/downloads/*
    chmod 755 /var/www/vibespeak/downloads/*.AppImage 2>/dev/null || true

    echo -e "${GREEN}✓ Files copied to downloads directory${NC}"
else
    echo -e "${RED}✗ No dist directory found${NC}"
    exit 1
fi

# Show results
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Build Complete!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Built files:${NC}"
ls -lh /var/www/vibespeak/downloads/

echo ""
echo -e "${YELLOW}Download URLs:${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "  Windows: http://$SERVER_IP/downloads/VibeSpeak-Setup.exe"
echo "  Linux AppImage: http://$SERVER_IP/downloads/VibeSpeak.AppImage"
echo "  Linux Deb: http://$SERVER_IP/downloads/vibespeak.deb"

echo ""
echo -e "${YELLOW}Note:${NC} macOS builds require macOS system."
echo "To build for macOS, run './build-desktop.sh' on a Mac."
