#!/bin/bash

####################################
# Build Desktop Apps for All Platforms
####################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VibeSpeak Desktop App Builder      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: Must run from project root${NC}"
    exit 1
fi

# Step 1: Build client
echo -e "${YELLOW}[1/3] Building client...${NC}"
cd client
if [ ! -d "node_modules" ]; then
    echo "Installing client dependencies..."
    npm install
fi
npm run build
cd ..
echo -e "${GREEN}✓ Client built${NC}"

# Step 2: Install desktop dependencies
echo -e "${YELLOW}[2/3] Installing desktop dependencies...${NC}"
cd desktop
if [ ! -d "node_modules" ]; then
    npm install
fi
cd ..
echo -e "${GREEN}✓ Desktop dependencies installed${NC}"

# Step 3: Build desktop apps
echo -e "${YELLOW}[3/3] Building desktop applications...${NC}"
cd desktop

echo "Building for all platforms..."
echo "This may take several minutes..."

# Build for all platforms
npm run build:win &
PID_WIN=$!
npm run build:mac &
PID_MAC=$!
npm run build:linux &
PID_LINUX=$!

# Wait for all builds
wait $PID_WIN $PID_MAC $PID_LINUX

echo ""
echo -e "${GREEN}✓ All builds complete!${NC}"
echo ""
echo -e "${YELLOW}Built applications:${NC}"
ls -lh dist/

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Build Complete!                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
echo "Applications are in: desktop/dist/"
echo ""
echo "Windows: VibeSpeak Setup.exe"
echo "macOS:   VibeSpeak.dmg"
echo "Linux:   VibeSpeak.AppImage, vibespeak.deb"
