#!/bin/bash
# Comprehensive log collection script for VoxMatrix testing

echo "==================================================================="
echo "  VoxMatrix Read Status Fix - Log Collection"
echo "==================================================================="
echo ""
echo "This script will collect logs for 60 seconds."
echo "Please:"
echo "  1. Open VoxMatrix app on your device"
echo "  2. Navigate to a chat room with unread messages" 
echo "  3. View the messages"
echo "  4. Navigate back to the room list"
echo "  5. Open the same chat room again"
echo ""
echo "Starting log collection in 5 seconds..."
sleep 5

# Clear old logs
adb logcat -c
echo "Logs cleared. Collecting..."
echo ""

# Collect logs for 60 seconds
adb logcat -T1 | grep -iE "(ChatBloc|ChatRepository|chat_repository|chat_bloc|markAsRead|markLastMessage|setReadMarker|LoadMessages|SubscribeToMessages|parseMatrixSdk|Skipping message|read marker|read receipt|marking.*read)" | tee "test_logs_$(date +%Y%m%d_%H%M%S).log" &

LOGPID=$!

# Wait 60 seconds
sleep 60

# Stop logging
kill $LOGPID 2>/dev/null || true

echo ""
echo "==================================================================="  
echo "  Log Collection Complete"
echo "==================================================================="
echo ""
echo "Log files created:"
ls -lh test_logs_*.log | tail -n 1
echo ""
echo "To view the logs:"
echo "  cat test_logs_*.log | tail -n 50"
echo ""
