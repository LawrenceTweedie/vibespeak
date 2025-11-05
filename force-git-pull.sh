#!/bin/bash

#############################################
# Force Git Pull - Reset Local Changes
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Force Git Pull                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

cd /var/www/vibespeak

echo -e "${YELLOW}Current git status:${NC}"
git status --short

echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  1. Remove untracked files"
echo "  2. Reset all local changes"
echo "  3. Pull latest code from repository"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove untracked files
echo -e "${YELLOW}Removing untracked files...${NC}"
git clean -fd

# Reset all changes
echo -e "${YELLOW}Resetting local changes...${NC}"
git reset --hard

# Pull latest
echo -e "${YELLOW}Pulling latest code...${NC}"
git pull origin claude/discord-clone-screen-share-011CUq4HgQ2XrpyNqyaR4tZr

echo ""
echo -e "${GREEN}✓ Repository updated!${NC}"
echo ""
echo -e "${YELLOW}Latest files:${NC}"
ls -la

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Fix Nginx: ./fix-nginx-spa.sh"
echo "  2. Setup HTTPS: ./setup-https-selfsigned.sh"
echo "  3. Fix services: ./complete-fix.sh"
