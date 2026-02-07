#!/bin/bash
# VoxMatrix Android Build Script - Optimized for Speed
# Uses persistent container with bind mounts for faster incremental builds

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
APP_DIR="$PROJECT_ROOT/app"

# Container name and image
CONTAINER_NAME="voxmatrix-builder-persistent"
IMAGE_NAME="voxmatrix/android-builder"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  VoxMatrix Fast Android Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Parse command line arguments
BUILD_TYPE="debug"
CLEAN_BUILD=false
INSTALL_DEVICE=false
BUILD_CMD="flutter build apk --debug"

while [[ $# -gt 0 ]]; do
    case $1 in
        --release|-r)
            BUILD_TYPE="release"
            BUILD_CMD="flutter build apk --release"
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
        --stop)
            echo -e "${YELLOW}Stopping persistent build container...${NC}"
            docker stop "$CONTAINER_NAME" 2>/dev/null || true
            docker rm "$CONTAINER_NAME" 2>/dev/null || true
            echo -e "${GREEN}Container stopped and removed${NC}"
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --release, -r    Build release APK instead of debug"
            echo "  --clean, -c      Clean build (remove old build artifacts)"
            echo "  --install, -i    Install APK to connected Android device"
            echo "  --stop           Stop and remove the persistent container"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "This script uses a persistent container for faster incremental builds."
            echo "The Gradle daemon stays running between builds for maximum speed."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Change to project root
cd "$PROJECT_ROOT"

# Function to create or start the persistent container
ensure_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${GREEN}Using existing persistent container${NC}"
        if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${BLUE}Starting container...${NC}"
            docker start "$CONTAINER_NAME" > /dev/null
            # Wait for container to be ready
            sleep 2
        fi
    else
        echo -e "${YELLOW}Creating new persistent container...${NC}"
        docker run -d \
            --name "$CONTAINER_NAME" \
            --restart=no \
            -v "${APP_DIR}:/workspace:rw" \
            -v voxmatrix-android-sdk:/opt/android-sdk \
            -v voxmatrix-gradle-cache:/root/.gradle \
            -v voxmatrix-pub-cache:/opt/flutter/.pub-cache \
            -w /workspace \
            --entrypoint tail \
            "$IMAGE_NAME" \
            -f /dev/null
        echo -e "${GREEN}Container created${NC}"
        sleep 3
    fi
}

# Function to build Flutter (will create image if needed)
ensure_image() {
    if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
        echo -e "${YELLOW}Builder image not found. Creating...${NC}"
        docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.builder" "$SCRIPT_DIR"
    fi
}

# Main build flow
main() {
    # Ensure image exists
    ensure_image

    # Ensure container is running
    ensure_container

    # Clean build if requested
    if [ "$CLEAN_BUILD" = true ]; then
        echo -e "${YELLOW}Cleaning build artifacts in container...${NC}"
        docker exec "$CONTAINER_NAME" sh -c "rm -rf build/ .dart_tool/" 2>/dev/null || true
    fi

    echo ""
    echo -e "${BLUE}Building $BUILD_TYPE APK...${NC}"
    echo -e "${BLUE}(Using persistent container for speed)${NC}"
    echo ""

    # Run the build in the container
    # We use exec to keep the Gradle daemon running
    docker exec -it "$CONTAINER_NAME" bash -c "
        export GRADLE_OPTS='-Dorg.gradle.daemon=true'
        flutter pub get 2>/dev/null || true
        $BUILD_CMD
    "

    BUILD_STATUS=$?

    echo ""

    if [ $BUILD_STATUS -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Build Successful!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""

        APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk"

        if [ -f "$APK_PATH" ]; then
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            echo -e "${GREEN}APK Location:${NC} $APK_PATH"
            echo -e "${GREEN}APK Size:${NC} $APK_SIZE"
            echo ""

            # Copy to root for easy access
            cp "$APK_PATH" "$PROJECT_ROOT/voxmatrix-${BUILD_TYPE}.apk"
            echo -e "${GREEN}APK copied to:${NC} ./voxmatrix-${BUILD_TYPE}.apk"
            echo ""

            # Install to device if requested
            if [ "$INSTALL_DEVICE" = true ] && command -v adb &> /dev/null; then
                if adb devices | grep -q "device$"; then
                    echo -e "${BLUE}Installing to connected device...${NC}"
                    adb install -r "$APK_PATH"
                else
                    echo -e "${YELLOW}No ADB device connected${NC}"
                fi
            fi

            echo ""
            echo -e "${BLUE}Container remains running for faster next build${NC}"
            echo -e "${BLUE}Use '$0 --stop' to stop the container when done${NC}"
        else
            echo -e "${RED}Warning: APK file not found${NC}"
            exit 1
        fi
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  Build Failed${NC}"
        echo -e "${RED}========================================${NC}"
        exit 1
    fi
}

main
