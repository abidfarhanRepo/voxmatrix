#!/bin/bash
# VoxMatrix Read Status Fix - Verification Test Script
# Run this script while manually testing the app

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  VoxMatrix - Read Status Fix Verification                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check device connection
if ! adb devices | grep -q "device$"; then
    echo "❌ No ADB device connected!"
    exit 1
fi

echo "✅ Device connected: $(adb devices | grep device | awk '{print $1}')"
echo ""
echo "📱 Current VoxMatrix version:"
adb shell dumpsys package org.voxmatrix.app | grep versionName || echo "  (not found)"
echo ""

# Clear logcat
adb logcat -c
echo "🧹 Logs cleared"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo " MANUAL TEST STEPS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  TEST: Read Status Persistence"
echo "   • Open a chat room with unread messages"  
echo "   • Observe: Messages load and display"
echo "   • VERIFY: Unread badge should clear"
echo "   • Go back to room list"
echo "   • VERIFY: Room should have 0 unread count"
echo "   • Close and reopen app"
echo "   • VERIFY: Room still shows 0 unread (not reset)"
echo ""
echo "2️⃣  TEST: No Blank Messages"
echo "   • Open a chat with various message types"
echo "   • Scroll through all messages"
echo "   • VERIFY: No empty/blank message bubbles"
echo "   • VERIFY: All text messages visible"
echo "   • VERIFY: Media messages show icons (📷🎥🎵📎)"
echo ""
echo "3️⃣  TEST: New Messages Auto-Read"
echo "   • Open a chat room"
echo "   • Have someone send you a new message"
echo "   • VERIFY: Message appears immediately"
echo "   • VERIFY: Read status updates automatically"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Start log monitoring
echo "📊 Starting log monitoring..."
echo "   Press Ctrl+C after testing to stop"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo " LIVE LOGS (filtered for chat activity)"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Monitor logs in real-time
adb logcat | grep --line-buffered -iE "(ChatBloc|markAsRead|Marking last message|Skipping message|parseMatrixSdk|LoadMessages|SubscribeToMessages)" | while read line; do
    echo "$(date '+%H:%M:%S') | $line"
done
