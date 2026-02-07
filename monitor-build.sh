#!/bin/bash

echo "Starting build monitoring for voxmatrix-build..."
echo "Monitoring at: $(date)"
echo ""

while true; do
    # Check if container is still running
    if ! docker ps | grep -q voxmatrix-build; then
        echo "Container stopped at: $(date)"
        
        # Check final logs for success/failure
        echo "Checking final build status..."
        LOGS=$(docker logs voxmatrix-build 2>&1)
        
        if echo "$LOGS" | grep -q "BUILD SUCCESSFUL"; then
            echo "✓ Build Status: SUCCESSFUL"
            
            # Check if APK exists
            APK_PATH="/home/xaf/Desktop/VoxMatrix/app/build/app/outputs/flutter-apk/app-debug.apk"
            if [ -f "$APK_PATH" ]; then
                echo "✓ APK found at: $APK_PATH"
                echo "Installing APK to device..."
                adb -s 192.168.10.5:46443 install -r "$APK_PATH" 2>&1
                echo "Installation complete at: $(date)"
            else
                echo "✗ APK not found at expected location: $APK_PATH"
            fi
            exit 0
            
        elif echo "$LOGS" | grep -q "BUILD FAILED"; then
            echo "✗ Build Status: FAILED"
            echo "Showing last 50 lines of error logs:"
            docker logs voxmatrix-build --tail 50 2>&1
            exit 1
        else
            echo "? Build status unclear - showing last 50 lines:"
            docker logs voxmatrix-build --tail 50 2>&1
            exit 1
        fi
    fi
    
    # Still running - show progress and wait
    echo "[$(date)] Build still running... checking logs (last 20 lines):"
    docker logs voxmatrix-build --tail 20 2>&1 | tail -20
    echo ""
    sleep 30
done
