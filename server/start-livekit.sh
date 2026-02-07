#!/bin/bash
# LiveKit Server startup script

cd /home/xaf/Desktop/VoxMatrix/server

# Generate API keys
docker run --rm livekit/livekit-server:latest generate-keys

# Start LiveKit server
docker-compose up -d livekit

echo "LiveKit server started"
echo "Checking logs..."
sleep 3
docker logs voxmatrix-livekit --tail 20
