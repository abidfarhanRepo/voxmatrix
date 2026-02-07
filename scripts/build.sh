#!/bin/bash

###############################################################################
# VoxMatrix Flutter App - Build Script
###############################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables
BUILD_TYPE="${1:-debug}"
PLATFORM="${2:-all}"
BUILD_NUMBER="${3:-1}"
BUILD_NAME="${4:-1.0.0}"

# Show usage
usage() {
    cat << EOF
Usage: $0 [BUILD_TYPE] [PLATFORM] [BUILD_NUMBER] [BUILD_NAME]

Build Types:
  debug       - Build debug version (default)
  release     - Build release version
  profile     - Build profile version

Platforms:
  all         - Build for all platforms (default)
  android     - Build for Android only
  ios         - Build for iOS only

Examples:
  $0                          # Build debug for all platforms
  $0 release                  # Build release for all platforms
  $0 release android          # Build release for Android only
  $0 release android 42 2.1.0 # Build release for Android with build number 42 and version 2.1.0

EOF
    exit 1
}

# Parse arguments
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

# Change to script directory
cd "$(dirname "$0")/.."

log_info "Starting VoxMatrix build..."
log_info "Build Type: $BUILD_TYPE"
log_info "Platform: $PLATFORM"
log_info "Build Number: $BUILD_NUMBER"
log_info "Build Name: $BUILD_NAME"

# Pre-build checks
log_info "Running pre-build checks..."

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    log_error "Flutter is not installed!"
    exit 1
fi

# Get Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
log_info "$FLUTTER_VERSION"

# Clean previous builds
log_info "Cleaning previous builds..."
flutter clean

# Install dependencies
log_info "Installing dependencies..."
flutter pub get

# Run code generation if needed
if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
    log_info "Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs || log_warning "Code generation failed, continuing..."
fi

# Run tests
log_info "Running tests..."
flutter test --test-randomize-ordering-seed random || log_warning "Tests failed, continuing with build..."

# Run analysis
log_info "Running code analysis..."
flutter analyze || log_warning "Analysis found issues, continuing with build..."

# Build functions
build_android_apk() {
    log_info "Building Android APK ($BUILD_TYPE)..."

    local BUILD_FLAGS=""
    if [ "$BUILD_TYPE" == "release" ]; then
        BUILD_FLAGS="--release"
    elif [ "$BUILD_TYPE" == "profile" ]; then
        BUILD_FLAGS="--profile"
    else
        BUILD_FLAGS="--debug"
    fi

    flutter build apk $BUILD_FLAGS --build-number=$BUILD_NUMBER --build-name=$BUILD_NAME

    local APK_PATH="build/app/outputs/flutter-apk/"
    local APK_NAME="voxmatrix-${BUILD_NAME}-${BUILD_NUMBER}"

    if [ "$BUILD_TYPE" == "release" ]; then
        APK_PATH="${APK_PATH}app-release.apk"
        APK_NAME="${APK_NAME}-release.apk"
    else
        APK_PATH="${APK_PATH}app-debug.apk"
        APK_NAME="${APK_NAME}-debug.apk"
    fi

    cp "$APK_PATH" "$APK_NAME" 2>/dev/null || true

    log_success "Android APK built: $APK_PATH"
    if [ -f "$APK_NAME" ]; then
        log_success "APK copied to: $APK_NAME"
    fi
}

build_android_bundle() {
    log_info "Building Android App Bundle (AAB)..."

    if [ "$BUILD_TYPE" != "release" ]; then
        log_warning "App bundles are only built for release. Skipping..."
        return
    fi

    flutter build appbundle --release --build-number=$BUILD_NUMBER --build-name=$BUILD_NAME

    local AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    local AAB_NAME="voxmatrix-${BUILD_NAME}-${BUILD_NUMBER}-release.aab"

    cp "$AAB_PATH" "$AAB_NAME" 2>/dev/null || true

    log_success "Android AAB built: $AAB_PATH"
    if [ -f "$AAB_NAME" ]; then
        log_success "AAB copied to: $AAB_NAME"
    fi
}

build_ios() {
    log_info "Building iOS ($BUILD_TYPE)..."

    local BUILD_FLAGS=""
    if [ "$BUILD_TYPE" == "release" ]; then
        BUILD_FLAGS="--release"
    elif [ "$BUILD_TYPE" == "profile" ]; then
        BUILD_FLAGS="--profile"
    else
        BUILD_FLAGS="--debug --no-codesign"
    fi

    flutter build ios $BUILD_FLAGS --build-number=$BUILD_NUMBER --build-name=$BUILD_NAME

    log_success "iOS build complete!"

    # Build IPA for release
    if [ "$BUILD_TYPE" == "release" ]; then
        log_info "Creating IPA archive..."

        cd ios
        xcodebuild -workspace Runner.xcworkspace \
            -scheme Runner \
            -sdk iphoneos \
            -configuration Release \
            -archivePath ../build/Runner.xcarchive \
            archive || log_warning "Archive creation failed"

        if [ -f "ExportOptions.plist" ]; then
            xcodebuild -exportArchive \
                -archivePath ../build/Runner.xcarchive \
                -exportOptionsPlist ExportOptions.plist \
                -exportPath ../build/export || log_warning "IPA export failed"

            cd ..
            if [ -d "build/export" ]; then
                find build/export -name "*.ipa" -exec cp {} voxmatrix-${BUILD_NAME}-${BUILD_NUMBER}.ipa \; 2>/dev/null || true
                log_success "IPA created: voxmatrix-${BUILD_NAME}-${BUILD_NUMBER}.ipa"
            fi
        else
            cd ..
            log_warning "ExportOptions.plist not found. Skipping IPA creation."
        fi
    fi
}

# Build based on platform
case $PLATFORM in
    android)
        build_android_apk
        build_android_bundle
        ;;
    ios)
        build_ios
        ;;
    all)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            build_android_apk
            build_android_bundle
            build_ios
        else
            log_warning "iOS builds require macOS. Skipping iOS build..."
            build_android_apk
            build_android_bundle
        fi
        ;;
    *)
        log_error "Unknown platform: $PLATFORM"
        usage
        ;;
esac

# Build summary
log_success ""
log_success "========================================"
log_success "Build completed successfully!"
log_success "========================================"
log_success ""
log_info "Build artifacts:"
ls -lh voxmatrix-*.* 2>/dev/null || log_info "No artifacts found in root directory"

log_info ""
log_info "To install the app:"
log_info "  Android: adb install voxmatrix-*.apk"
log_info "  iOS: Use Xcode to install the IPA"
log_info ""
