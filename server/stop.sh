#!/bin/bash
# VoxMatrix Stop Script
# This script stops all Matrix server services

set -e

echo "=== VoxMatrix Stop Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if containers are running
if ! docker-compose ps -q | grep -q .; then
    echo -e "${YELLOW}No services are currently running.${NC}"
    exit 0
fi

echo -e "${YELLOW}Stopping VoxMatrix services...${NC}"
echo ""

# Stop services gracefully
docker-compose down

echo -e "${GREEN}=== Services Stopped ===${NC}"
echo ""
echo "All services have been stopped successfully."
echo ""
echo "To start services again, run: ./start.sh"
echo ""
