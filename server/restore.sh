#!/bin/bash
# VoxMatrix Restore Script
# This script restores backups created by backup.sh

set -e

echo "=== VoxMatrix Restore Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if backup name was provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No backup specified${NC}"
    echo ""
    echo "Usage: ./restore.sh <backup_name>"
    echo ""
    echo "Available backups:"
    ls -lht ./backups/*.tar.gz 2>/dev/null | awk '{print $9}' | sed 's|./backups/||' | sed 's|.tar.gz||' || echo "No backups found"
    exit 1
fi

BACKUP_NAME=$1
BACKUP_FILE="./backups/${BACKUP_NAME}.tar.gz"
CHECKSUM_FILE="./backups/${BACKUP_NAME}.sha256"

# Check if backup exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup '$BACKUP_NAME' not found!${NC}"
    echo ""
    echo "Available backups:"
    ls -lht ./backups/*.tar.gz 2>/dev/null | awk '{print $9}' | sed 's|./backups/||' | sed 's|.tar.gz||' || echo "No backups found"
    exit 1
fi

# Verify checksum if available
if [ -f "$CHECKSUM_FILE" ]; then
    echo -e "${YELLOW}Verifying backup checksum...${NC}"
    cd backups
    if sha256sum -c "${BACKUP_NAME}.sha256" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Checksum verified${NC}"
    else
        echo -e "${RED}✗ Checksum verification failed! Backup may be corrupted.${NC}"
        exit 1
    fi
    cd ..
else
    echo -e "${YELLOW}Warning: No checksum file found, skipping verification${NC}"
fi

# Warning message
echo ""
echo -e "${RED}========================================${NC}"
echo -e "${RED}WARNING: This will REPLACE all data!${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo "This will restore from: $BACKUP_NAME"
echo ""
echo "The following will be affected:"
echo "  - PostgreSQL database"
echo "  - Dendrite configuration"
echo "  - Dendrite media files"
echo "  - Matrix private key"
echo "  - Caddy TLS certificates"
echo ""
read -p "Are you sure you want to continue? (yes/no) " -r
echo ""

if [[ ! $REPLY =~ ^yes$ ]]; then
    echo -e "${YELLOW}Restore cancelled.${NC}"
    exit 0
fi

# Stop services
echo -e "${YELLOW}Stopping services...${NC}"
docker-compose down

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Extract backup
echo -e "${YELLOW}Extracting backup...${NC}"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Check if backup_info.txt exists (valid backup check)
if [ ! -f "$TEMP_DIR/backup_info.txt" ]; then
    echo -e "${RED}Error: Invalid backup file!${NC}"
    exit 1
fi

# Display backup info
echo ""
echo -e "${GREEN}=== Backup Information ===${NC}"
cat "$TEMP_DIR/backup_info.txt"
echo ""

# Restore database
echo -e "${YELLOW}Restoring PostgreSQL database...${NC}"
if [ -f "$TEMP_DIR/database.sql" ]; then
    docker-compose up -d postgres
    sleep 5

    # Load environment variables
    if [ -f "$TEMP_DIR/dendrite/.env.backup" ]; then
        source "$TEMP_DIR/dendrite/.env.backup"
    elif [ -f .env ]; then
        source .env
    fi

    docker-compose exec -T postgres psql \
        -U "${POSTGRES_USER:-dendrite}" \
        -d "${POSTGRES_DB:-dendrite}" \
        < "$TEMP_DIR/database.sql"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database restored successfully${NC}"
    else
        echo -e "${RED}✗ Database restore failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Database dump not found in backup${NC}"
    exit 1
fi

# Restore Dendrite data
echo -e "${YELLOW}Restoring Dendrite data...${NC}"

# Restore matrix key
if [ -f "$TEMP_DIR/dendrite/matrix_key.pem" ]; then
    cp "$TEMP_DIR/dendrite/matrix_key.pem" data/dendrite/
    chmod 600 data/dendrite/matrix_key.pem
fi

# Restore media files
if [ -f "$TEMP_DIR/dendrite/media.tar.gz" ]; then
    mkdir -p data/dendrite/
    tar -xzf "$TEMP_DIR/dendrite/media.tar.gz" -C data/dendrite/
fi

# Restore configuration (optional)
if [ -f "$TEMP_DIR/dendrite/dendrite.yaml" ]; then
    read -p "Restore dendrite.yaml configuration? (yes/no) " -r
    if [[ $REPLY =~ ^yes$ ]]; then
        cp "$TEMP_DIR/dendrite/dendrite.yaml" ./dendrite.yaml
    fi
fi

echo -e "${GREEN}✓ Dendrite data restored successfully${NC}"

# Restore Caddy data
echo -e "${YELLOW}Restoring Caddy data...${NC}"
if [ -f "$TEMP_DIR/caddy_data.tar.gz" ]; then
    tar -xzf "$TEMP_DIR/caddy_data.tar.gz" -C ./
    echo -e "${GREEN}✓ Caddy data restored successfully${NC}"
else
    echo -e "${YELLOW}No Caddy data found in backup${NC}"
fi

# Start services
echo ""
echo -e "${YELLOW}Starting services...${NC}"
docker-compose up -d

# Wait for services to start
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check service status
echo ""
echo -e "${GREEN}=== Service Status ===${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}=== Restore Complete! ===${NC}"
echo ""
echo "Your Matrix server has been restored from backup: $BACKUP_NAME"
echo ""
echo "Please verify:"
echo "  - Check if users can login"
echo "  - Check if rooms are accessible"
echo "  - Check if media files are loading"
echo ""
echo "If you encounter issues, check the logs:"
echo "  docker-compose logs -f [service]"
echo ""
