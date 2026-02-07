# VoxMatrix Docker Build Guide

This directory contains Docker configurations for building the VoxMatrix Flutter Android application without installing Android SDK, Gradle, or Flutter on your host machine.

---

## Quick Start

### Build Debug APK
```bash
cd /home/xaf/Desktop/VoxMatrix/docker
./build-android.sh
```

### Build Release APK
```bash
./build-android.sh --release
```

### Build and Install to Device
```bash
./build-android.sh --install
```

---

## File Structure

```
docker/
├── Dockerfile.android          # Docker image for Android builds
├── docker-compose.yml          # Container orchestration
├── build-android.sh            # Helper build script
└── README.md                   # This file
```

---

## Prerequisites

### Required
- **Docker** - Container runtime
  ```bash
  # Check if installed
  docker --version
  ```

- **Docker Compose** - Multi-container orchestration
  ```bash
  # Check if installed
  docker compose version
  # or
  docker-compose --version
  ```

### Optional
- **ADB (Android Debug Bridge)** - For installing APK to connected devices
  ```bash
  # Install on Ubuntu/Debian
  sudo apt-get install android-tools-adb

  # Check device connection
  adb devices
  ```

---

## Build Options

### Using the Helper Script (Recommended)

```bash
# Basic usage
./build-android.sh

# All options
./build-android.sh [OPTIONS]

Options:
  --release, -r    Build release APK (smaller, optimized)
  --clean, -c      Clean build artifacts before building
  --install, -i    Install APK to connected Android device
  --help, -h       Show help message
```

### Using Docker Compose Directly

```bash
# Build debug APK
docker compose -f docker/docker-compose.yml run --rm android-builder

# Build release APK
docker compose -f docker/docker-compose.yml run --rm android-builder-release

# Rebuild container (after Dockerfile changes)
docker compose -f docker/docker-compose.yml build android-builder
```

---

## Build Artifacts

After successful build, the APK will be available at:

| Build Type | Location | Also Copied To |
|------------|----------|----------------|
| Debug | `app/build/app/outputs/flutter-apk/app-debug.apk` | `./voxmatrix-debug.apk` |
| Release | `app/build/app/outputs/flutter-apk/app-release.apk` | `./voxmatrix-release.apk` |

---

## Docker Volumes (Caching)

The setup uses Docker volumes to cache dependencies, speeding up subsequent builds:

| Volume | Purpose | Location |
|--------|---------|----------|
| `android-sdk-cache` | Android SDK and tools | `/opt/android-sdk` |
| `flutter-pub-cache` | Flutter package cache | `/root/.pub-cache` |
| `flutter-build-cache` | Flutter build cache | `/opt/flutter/.cache` |

### Clear Caches
```bash
# Remove all caches
docker volume rm voxmatrix_android-sdk-cache \
                 voxmatrix_flutter-pub-cache \
                 voxmatrix_flutter-build-cache

# Or remove all unused volumes
docker volume prune
```

---

## Troubleshooting

### Build Fails with "Docker command not found"
```bash
# Ensure Docker daemon is running
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (optional, avoids sudo)
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

### Build Fails with Permission Errors
```bash
# Fix file permissions
sudo chown -R $USER:$USER /home/xaf/Desktop/VoxMatrix
```

### Build is Slow on First Run
First build downloads Flutter SDK (~1GB) and Android SDK components. Subsequent builds use cached volumes and are much faster.

### ADB Cannot Connect to Device
```bash
# Check if device is connected
adb devices

# If empty, enable USB debugging on device:
# 1. Settings > About Phone > Tap Build Number 7 times
# 2. Settings > Developer Options > Enable USB Debugging
# 3. Connect device and accept debugging prompt

# Restart ADB server
adb kill-server
adb start-server
```

### Out of Space Errors
```bash
# Clean Docker system
docker system prune -a --volumes

# Check disk usage
docker system df
```

---

## Advanced Usage

### Custom Build Configuration

Edit `docker-compose.yml` to modify build parameters:

```yaml
command: >
  bash -c "
    flutter build apk --debug \
      --target-platform android-arm64 \
      --split-per-abi
  "
```

### Building for Different Architectures

```bash
# ARM64 (most modern devices)
flutter build apk --debug --target-platform android-arm64

# ARM32 (older devices)
flutter build apk --debug --target-platform armeabi-v7a

# x86_64 (emulators)
flutter build apk --debug --target-platform android-x64
```

### Building App Bundle (AAB) for Play Store

```bash
# Modify command in docker-compose.yml:
flutter build appbundle --release
```

---

## Docker Image Details

### Base Image
- **eclipse-temurin:17-jdk** - OpenJDK 17 from Eclipse Temurin

### Installed Components
- Flutter SDK (stable channel)
- Android SDK (command-line tools)
- Android Platform Tools
- Android Build Tools 34.0.0
- Android Platform 34
- System dependencies (wget, unzip, git, curl)

### Environment Variables
```bash
FLUTTER_HOME=/opt/flutter
ANDROID_SDK_ROOT=/opt/android-sdk
ANDROID_HOME=/opt/android-sdk
PATH includes Flutter and Android tools
```

---

## Comparison: Native vs Docker Build

| Aspect | Native Build | Docker Build |
|--------|--------------|--------------|
| Setup | Install JDK, Android SDK, Flutter | Just Docker |
| Disk Space | ~4GB on host | ~4GB in container |
| Isolation | Mixed with host system | Fully isolated |
| Reproducibility | Depends on host | Always same |
| Cleanup | Manual | `docker system prune` |
| Version Management | Manual | Change Dockerfile |

---

## Performance

### First Build
- Download Flutter SDK: ~1GB
- Download Android SDK: ~500MB
- Build time: ~5-10 minutes

### Subsequent Builds (with cache)
- Download: ~0MB (cached)
- Build time: ~2-3 minutes

---

## Security Notes

1. **Privileged Mode**: The container runs in privileged mode for USB device access. Only needed for `--install` option.

2. **ADB Keys**: The container mounts `~/.android` which contains ADB authentication keys.

3. **USB Devices**: `/dev/bus/usb` is mounted for physical device installation.

---

## Updating the Build Environment

### Update Flutter SDK
```bash
# Rebuild container without cache
docker compose build --no-cache android-builder
```

### Change Android SDK Version
Edit `Dockerfile.android`:
```dockerfile
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"
```

---

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Build Android APK
  run: |
    cd /home/xaf/Desktop/VoxMatrix/docker
    ./build-android.sh --release
```

### GitLab CI Example
```yaml
build:android:
  script:
    - cd docker && ./build-android.sh --release
  artifacts:
    paths:
      - voxmatrix-release.apk
```

---

## Support

For issues or questions:

1. Check Docker logs: `docker compose logs android-builder`
2. Check Flutter doctor in container: `docker compose run --rm android-builder flutter doctor -v`
3. Review this documentation
4. Check VoxMatrix main README

---

*Last Updated: 2025-01-31*
