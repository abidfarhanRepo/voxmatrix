#!/bin/bash
# VoxMatrix Tailscale Setup Script
# This script helps you set up the VoxMatrix server with Tailscale networking

set -e

echo "================================"
echo "VoxMatrix Tailscale Setup"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Tailscale is installed
echo -e "${YELLOW}Checking for Tailscale...${NC}"
if ! command -v tailscale &> /dev/null; then
    echo -e "${RED}Tailscale is not installed!${NC}"
    echo ""
    echo "Please install Tailscale first:"
    echo "  - Debian/Ubuntu: curl -fsSL https://tailscale.com/install.sh | sh"
    echo "  - Fedora/RHEL:   curl -fsSL https://tailscale.com/install.sh | sh"
    echo "  - Arch:         sudo pacman -S tailscale"
    echo ""
    exit 1
fi

echo -e "${GREEN}Tailscale found!${NC}"
echo ""

# Check if Tailscale is running
echo -e "${YELLOW}Checking Tailscale status...${NC}"
if ! tailscale status &> /dev/null; then
    echo -e "${RED}Tailscale is not running!${NC}"
    echo ""
    echo "Please start Tailscale first:"
    echo "  sudo systemctl enable --now tailscaled"
    echo "  sudo tailscale up"
    echo ""
    exit 1
fi

echo -e "${GREEN}Tailscale is running!${NC}"
echo ""

# Get Tailscale IP
TS_IP=$(tailscale ip -4)
echo -e "${GREEN}Your Tailscale IPv4 address: $TS_IP${NC}"
echo ""

# Check for Tailscale hostname (MagicDNS)
if command -v hostname &> /dev/null; then
    HOSTNAME=$(hostname)
    echo "Your hostname: $HOSTNAME"
fi

# Get Tailscale URL (if MagicDNS is enabled)
TS_URL=$(tailscale status --json 2>/dev/null | grep -o '"TailnetName":"[^"]*"' | cut -d'"' -f4 | head -1)
if [ -n "$TS_URL" ]; then
    echo -e "${GREEN}Your Tailscale network: $TS_URL${NC}"
fi

echo ""
echo "================================"
echo "Creating environment file..."
echo "================================"
echo ""

# Create .env from template
if [ -f .env ]; then
    echo -e "${YELLOW}.env file already exists. Backing up...${NC}"
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
fi

# Generate secure passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
TURN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Create .env file
cat > .env << EOF
# VoxMatrix Environment Configuration for Tailscale
# Generated: $(date)

# Tailscale IP address
TAILSCALE_IP=$TS_IP

# Matrix server name (using local hostname)
SERVER_NAME=voxmatrix.local

# PostgreSQL Configuration
POSTGRES_USER=dendrite
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=dendrite

# TURN Server Configuration
TURN_USERNAME=turnuser
TURN_PASSWORD=$TURN_PASSWORD

# Docker Settings
COMPOSE_PROJECT_NAME=voxmatrix
DATA_DIR=./data
EOF

echo -e "${GREEN}.env file created!${NC}"
echo ""

# Create data directories
echo "Creating data directories..."
mkdir -p data/postgres data/dendrite data/coturn
chmod 755 data/postgres data/dendrite data/coturn

# Generate Matrix private key
echo ""
echo "Generating Matrix private key..."
if [ ! -f data/dendrite/matrix_key.pem ]; then
    openssl genpkey -out data/dendrite/matrix_key.pem -algorithm ed25519 2>/dev/null || \
    openssl genpkey -out data/dendrite/matrix_key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
    chmod 600 data/dendrite/matrix_key.pem
    echo -e "${GREEN}Matrix key generated!${NC}"
else
    echo -e "${YELLOW}Matrix key already exists.${NC}"
fi

echo ""
echo "================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "================================"
echo ""
echo "Your Tailscale Configuration:"
echo "  Tailscale IP:      $TS_IP"
echo "  Matrix Server:     http://$TS_IP:8008"
echo "  TURN Server:       turn:$TS_IP:3478"
echo ""
echo "To start the server:"
echo "  docker-compose -f docker-compose.tailscale.yml up -d"
echo ""
echo "To view logs:"
echo "  docker-compose -f docker-compose.tailscale.yml logs -f"
echo ""
echo "To stop the server:"
echo "  docker-compose -f docker-compose.tailscale.yml down"
echo ""
echo "================================"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "1. Keep the .env file safe - it contains your passwords"
echo "2. All devices on your Tailscale network can connect"
echo "3. For Matrix clients, use: http://$TS_IP:8008"
echo "4. For TURN in clients, use: turn:$TS_IP:3478"
echo "5. Store backup of passwords securely!"
echo ""
