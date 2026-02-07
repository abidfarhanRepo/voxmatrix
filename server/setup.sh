#!/bin/bash
# VoxMatrix Setup Script
# This script initializes the Matrix server environment

set -e

echo "=== VoxMatrix Setup Script ==="
echo "This script will set up your Matrix server environment"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}.env file created. Please edit it with your settings before continuing.${NC}"
        echo ""
        echo "Required changes in .env:"
        echo "  - SERVER_NAME (your Matrix domain)"
        echo "  - SERVER_IP (your public IP)"
        echo "  - POSTGRES_PASSWORD (secure password)"
        echo "  - TURN_USERNAME and TURN_PASSWORD"
        echo "  - CADDY_EMAIL (for Let's Encrypt)"
        echo ""
        read -p "Have you configured the .env file? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}Please configure .env file and run this script again.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: .env.example not found!${NC}"
        exit 1
    fi
fi

# Source environment variables
source .env

echo -e "${GREEN}Checking prerequisites...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check if ports are available
echo -e "${YELLOW}Checking if required ports are available...${NC}"
ports=(80 443 8008 8448 3478 5349 5432)
for port in "${ports[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}Warning: Port $port is already in use!${NC}"
    fi
done

# Create directory structure
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p data/dendrite
mkdir -p data/postgres
mkdir -p data/caddy/logs
mkdir -p coturn
chmod -R 755 data/

# Generate private key for Dendrite if it doesn't exist
if [ ! -f data/dendrite/matrix_key.pem ]; then
    echo -e "${GREEN}Generating Matrix private key...${NC}"
    docker run --rm -v $(pwd)/data/dendrite:/var/dendrite \
        matrix-org/dendrite-polylith:latest \
        generate-keys --private-key /var/dendrite/matrix_key.pem
    chmod 600 data/dendrite/matrix_key.pem
else
    echo -e "${YELLOW}Matrix private key already exists, skipping generation.${NC}"
fi

# Create media directory
mkdir -p data/dendrite/media
mkdir -p data/dendrite/upload

# Generate TURN server password if not set
if [ -z "$TURN_PASSWORD" ] || [ "$TURN_PASSWORD" == "changeme" ]; then
    echo -e "${YELLOW}Generating secure TURN password...${NC}"
    TURN_PASSWORD=$(openssl rand -base64 32)
    echo "TURN_PASSWORD=$TURN_PASSWORD" >> .env
fi

# Generate PostgreSQL password if not set
if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" == "changeme" ]; then
    echo -e "${YELLOW}Generating secure PostgreSQL password...${NC}"
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> .env
fi

# Set proper permissions
echo -e "${GREEN}Setting proper permissions...${NC}"
chmod 600 .env
chmod 644 docker-compose.yml
chmod 644 dendrite.yaml
chmod 644 Caddyfile
chmod 644 coturn/turnserver.conf

# Create .gitignore for sensitive data
if [ ! -f .gitignore ]; then
    echo -e "${GREEN}Creating .gitignore file...${NC}"
    cat > .gitignore << 'EOF'
.env
data/
coturn/turnserver.db
coturn/*.log
*.log
*.key
*.pem
!coturn/turnserver.conf
EOF
fi

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and update .env with your domain and credentials"
echo "  2. Ensure DNS is configured:"
echo "     - ${SERVER_NAME} -> ${SERVER_IP}"
echo "     - _matrix._tcp.${SERVER_NAME} SRV 10 0 8448 ${SERVER_NAME}"
echo "  3. Run ./start.sh to start all services"
echo "  4. Check status with: docker-compose ps"
echo ""
echo "Important files:"
echo "  - .env          : Environment variables"
echo "  - docker-compose.yml : Service definitions"
echo "  - dendrite.yaml : Matrix server config"
echo "  - Caddyfile     : Reverse proxy config"
echo ""
