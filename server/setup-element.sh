#!/bin/bash
# VoxMatrix Setup Script - Configure /etc/hosts for Element Web access

echo "================================"
echo "VoxMatrix Element Web Setup"
echo "================================"
echo ""
echo "This script will help you access your Matrix server from Element Web"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo:"
    echo "  sudo $0"
    exit 1
fi

HOSTS_ENTRY="100.92.210.91 voxmatrix.local"
HOSTS_FILE="/etc/hosts"

echo "Adding voxmatrix.local to /etc/hosts..."
echo ""

# Check if entry already exists
if grep -q "voxmatrix.local" "$HOSTS_FILE"; then
    echo "Entry already exists. Removing old entry..."
    sed -i '/voxmatrix.local/d' "$HOSTS_FILE"
fi

# Add new entry
echo "$HOSTS_ENTRY" >> "$HOSTS_FILE"

echo ""
echo "✓ Added to /etc/hosts:"
echo "  $HOSTS_ENTRY"
echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "Now you can access your Matrix server with Element Web:"
echo ""
echo "1. Open this URL in your browser:"
echo "   https://app.element.io/#/login?hs_url=http://voxmatrix.local:8008&hs_name=VoxMatrix"
echo ""
echo "2. Or register new account:"
echo "   https://app.element.io/#/register?hs_url=http://voxmatrix.local:8008"
echo ""
echo "3. In Element Web:"
echo "   - Click 'Sign In'"
echo "   - Click 'Edit' next to 'matrix.org'"
echo "   - Enter: http://voxmatrix.local:8008"
echo "   - Or enter server name: voxmatrix.local"
echo ""
echo "To test the server:"
echo "  curl http://voxmatrix.local:8008/_matrix/client/versions"
echo ""
echo "To remove later (run as root):"
echo "  sudo sed -i '/voxmatrix.local/d' /etc/hosts"
echo ""
