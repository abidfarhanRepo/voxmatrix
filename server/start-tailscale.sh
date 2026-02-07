#!/bin/bash
# Quick start script for VoxMatrix on Tailscale

set -e

COMPOSE_FILE="docker-compose.tailscale.yml"

echo "Starting VoxMatrix (Tailscale mode)..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please run: ./tailscale-setup.sh first"
    exit 1
fi

# Load Tailscale IP from .env
source .env

echo "Tailscale IP: $TAILSCALE_IP"
echo "Server name: $SERVER_NAME"
echo ""

# Start services
docker-compose -f $COMPOSE_FILE up -d

echo ""
echo "Waiting for services to be healthy..."
sleep 10

# Check if services are running
echo ""
echo "Service Status:"
docker-compose -f $COMPOSE_FILE ps

echo ""
echo "================================"
echo -e "\033[0;32mVoxMatrix is running!\033[0m"
echo "================================"
echo ""
echo "Access URLs:"
echo "  Matrix Client API:  http://$TAILSCALE_IP:8008"
echo "  Well-known config:  http://$TAILSCALE_IP:8008/.well-known/matrix/client"
echo ""
echo "For Flutter app, use:"
echo "  Homeserver: http://$TAILSCALE_IP:8008"
echo ""
echo "View logs: docker-compose -f $COMPOSE_FILE logs -f"
echo "Stop:      docker-compose -f $COMPOSE_FILE down"
echo ""
