#!/bin/bash
# VoxMatrix Start Script
# This script starts all Matrix server services

set -e

echo "=== VoxMatrix Start Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please run ./setup.sh first."
    exit 1
fi

# Source environment variables
source .env

# Check if setup has been run
if [ ! -f data/dendrite/matrix_key.pem ]; then
    echo -e "${YELLOW}Warning: Matrix private key not found. Running setup...${NC}"
    ./setup.sh
fi

echo -e "${GREEN}Starting VoxMatrix services...${NC}"
echo ""

# Stop any existing containers first
echo -e "${YELLOW}Stopping any existing services...${NC}"
docker-compose down 2>/dev/null || true

# Pull latest images
echo -e "${GREEN}Pulling latest Docker images...${NC}"
docker-compose pull

# Start services
echo -e "${GREEN}Starting services...${NC}"
docker-compose up -d

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 5

# Check service status
echo ""
echo -e "${GREEN}=== Service Status ===${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}Checking service health...${NC}"

# Function to check if a service is responding
check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -fSs "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $service_name is ready${NC}"
            return 0
        fi
        echo -e "${YELLOW}Waiting for $service_name... (attempt $attempt/$max_attempts)${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done

    echo -e "${RED}✗ $service_name failed to start${NC}"
    return 1
}

# Check PostgreSQL
check_service "PostgreSQL" "http://localhost:5432" || true

# Check Dendrite (may take longer)
check_service "Dendrite Client API" "http://localhost:8008/_matrix/client/versions" || true

echo ""
echo -e "${GREEN}=== Services Started Successfully! ===${NC}"
echo ""
echo "Access points:"
echo "  - Client API:       https://${SERVER_NAME}/_matrix/client/"
echo "  - Federation API:   https://${SERVER_NAME}:8448/"
echo "  - Web client:       https://${SERVER_NAME}/"
echo ""
echo "Useful commands:"
echo "  - View logs:        docker-compose logs -f [service]"
echo "  - Stop services:    ./stop.sh"
echo "  - Backup data:      ./backup.sh"
echo "  - Check status:     docker-compose ps"
echo ""
echo "To create your first admin user, run:"
echo "  docker-compose exec dendrite /create-account"
echo ""
