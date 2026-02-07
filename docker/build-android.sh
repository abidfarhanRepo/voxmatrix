#!/bin/bash
# VoxMatrix Android Build Script
# This script builds the Android APK using Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  VoxMatrix Android Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    echo "Please install Docker Compose first"
    exit 1
fi

# Determine docker compose command
DOCKER_COMPOSE="docker compose"
if ! docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
fi

# Parse command line arguments
BUILD_TYPE="debug"
CLEAN_BUILD=false
INSTALL_DEVICE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --release|-r)
            BUILD_TYPE="release"
            shift
            ;;
        --clean|-c)
            CLEAN_BUILD=true
            shift
            ;;
        --install|-i)
            INSTALL_DEVICE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --release, -r    Build release APK instead of debug"
            echo "  --clean, -c      Clean build (remove old build artifacts)"
            echo "  --install, -i    Install APK to connected Android device"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                  # Build debug APK"
            echo "  $0 --release        # Build release APK"
            echo "  $0 --clean          # Clean build debug APK"
            echo "  $0 --release -i     # Build and install release APK"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Change to project root
cd "$PROJECT_ROOT"

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}Cleaning old build artifacts...${NC}"
    rm -rf app/build/
    rm -rf app/.dart_tool/
    echo -e "${GREEN}Clean complete${NC}"
    echo ""
fi

# Build the APK
echo -e "${BLUE}Building $BUILD_TYPE APK...${NC}"
echo ""

if [ "$BUILD_TYPE" = "release" ]; then
    $DOCKER_COMPOSE -f docker/docker-compose.yml build android-builder-release
    $DOCKER_COMPOSE -f docker/docker-compose.yml run --rm android-builder-release
else
    $DOCKER_COMPOSE -f docker/docker-compose.yml build android-builder
    $DOCKER_COMPOSE -f docker/docker-compose.yml run --rm android-builder
fi

BUILD_STATUS=$?

echo ""

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Build Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    APK_PATH="app/build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk"

    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}APK Location:${NC} $APK_PATH"
        echo -e "${GREEN}APK Size:${NC} $APK_SIZE"
        echo ""

        # Copy APK to a more accessible location
        cp "$APK_PATH" "./voxmatrix-${BUILD_TYPE}.apk"
        echo -e "${GREEN}APK copied to:${NC} ./voxmatrix-${BUILD_TYPE}.apk"
        echo ""

        # Install to device if requested
        if [ "$INSTALL_DEVICE" = true ]; then
            echo -e "${BLUE}Installing to connected device...${NC}"

            # Check if ADB is available (either on host or in container)
            if command -v adb &> /dev/null; then
                adb install -r "$APK_PATH"
            else
                echo -e "${YELLOW}ADB not found on host${NC}"
                echo "Install ADB or manually transfer the APK to your device"
            fi
        fi

        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "  1. Transfer the APK to your Android device"
        echo "  2. Enable 'Install from unknown sources' in device settings"
        echo "  3. Open the APK file to install VoxMatrix"
        echo ""
        echo -e "${BLUE}Or install via ADB:${NC}"
        echo "  adb install -r voxmatrix-${BUILD_TYPE}.apk"
    else
        echo -e "${RED}Warning: APK file not found at expected location${NC}"
        exit 1
    fi
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  Build Failed${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Check the output above for errors"
    exit 1
fi
