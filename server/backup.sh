#!/bin/bash
# VoxMatrix Backup Script
# This script creates backups of database and media files

set -e

echo "=== VoxMatrix Backup Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found!${NC}"
    exit 1
fi

# Backup directory
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="voxmatrix_backup_${TIMESTAMP}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Creating backup: $BACKUP_NAME${NC}"
echo ""

# Create temporary directory for this backup
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Backup PostgreSQL database
echo -e "${YELLOW}Backing up PostgreSQL database...${NC}"
docker-compose exec -T postgres pg_dump \
    -U "${POSTGRES_USER:-dendrite}" \
    -d "${POSTGRES_DB:-dendrite}" \
    --clean \
    --if-exists \
    --format=plain \
    > "$TEMP_DIR/database.sql"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database backup successful${NC}"
else
    echo -e "${RED}✗ Database backup failed${NC}"
    exit 1
fi

# Backup Dendrite configuration and media
echo -e "${YELLOW}Backing up Dendrite data...${NC}"
mkdir -p "$TEMP_DIR/dendrite"

# Copy configuration files
cp dendrite.yaml "$TEMP_DIR/dendrite/" 2>/dev/null || true
cp .env "$TEMP_DIR/dendrite/.env.backup" 2>/dev/null || true

# Copy media directory if it exists
if [ -d "data/dendrite/media" ]; then
    echo -e "${YELLOW}Backing up media files...${NC}"
    tar -czf "$TEMP_DIR/dendrite/media.tar.gz" -C data/dendrite media 2>/dev/null || true
fi

# Copy matrix key
if [ -f "data/dendrite/matrix_key.pem" ]; then
    cp data/dendrite/matrix_key.pem "$TEMP_DIR/dendrite/"
fi

echo -e "${GREEN}✓ Dendrite data backup successful${NC}"

# Backup Caddy data (certificates)
echo -e "${YELLOW}Backing up Caddy data...${NC}"
if [ -d "data/caddy" ]; then
    tar -czf "$TEMP_DIR/caddy_data.tar.gz" -C data caddy 2>/dev/null || true
    echo -e "${GREEN}✓ Caddy data backup successful${NC}"
fi

# Create backup info file
cat > "$TEMP_DIR/backup_info.txt" << EOF
VoxMatrix Backup
================
Date: $(date)
Timestamp: $TIMESTAMP
Server Name: ${SERVER_NAME:-not set}
Server IP: ${SERVER_IP:-not set}

Contents:
- PostgreSQL database dump (database.sql)
- Dendrite configuration
- Dendrite media files (media.tar.gz)
- Matrix private key (matrix_key.pem)
- Caddy TLS certificates (caddy_data.tar.gz)
- Environment variables (.env.backup)

To restore, use: ./restore.sh $BACKUP_NAME
EOF

# Create final backup archive
echo ""
echo -e "${YELLOW}Creating backup archive...${NC}"
tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" -C "$TEMP_DIR" .

# Calculate checksum
BACKUP_CHECKSUM=$(sha256sum "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | awk '{print $1}')
echo "$BACKUP_CHECKSUM" > "$BACKUP_DIR/${BACKUP_NAME}.sha256"

# Backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)

# List all backups
echo ""
echo -e "${GREEN}=== Backup Complete! ===${NC}"
echo ""
echo "Backup created: ${BACKUP_NAME}.tar.gz"
echo "Size: $BACKUP_SIZE"
echo "SHA256: $BACKUP_CHECKSUM"
echo "Location: $BACKUP_DIR/"
echo ""

# List recent backups
echo -e "${YELLOW}Recent backups:${NC}"
ls -lht "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -5 || echo "No backups found"
echo ""

# Cleanup old backups (keep last 10)
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ $BACKUP_COUNT -gt 10 ]; then
    echo -e "${YELLOW}Cleaning up old backups (keeping last 10)...${NC}"
    ls -1t "$BACKUP_DIR"/*.tar.gz | tail -n +11 | xargs -r rm
    ls -1t "$BACKUP_DIR"/*.sha256 | tail -n +11 | xargs -r rm
fi

echo "To restore this backup, run:"
echo "  ./restore.sh ${BACKUP_NAME}"
echo ""
