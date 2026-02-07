# Build Android APK with Docker

This project includes a Dockerized build pipeline for Android APKs.

## Prerequisites

- Docker installed and running
- Project located at `/home/xaf/Desktop/VoxMatrix`

## Build Debug APK

From the repo root:

```bash
./docker/build-android.sh
```

This builds the debug APK inside a container and copies it to:

- `app/build/app/outputs/flutter-apk/app-debug.apk`
- `voxmatrix-debug.apk`

## Install via Wireless ADB

```bash
adb connect 100.98.138.106:36757
adb install -r voxmatrix-debug.apk
```

## Build Release APK

If you have signing configured, you can build release APK:

```bash
docker-compose -f docker/docker-compose.yml --profile release up --build
```

Output:

- `app/build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

### Build fails due to Gradle or Flutter

- Check `app/android/gradle.properties`
- Ensure Flutter version in Docker image is compatible

### APK not found

- Verify build succeeded and check:
  - `app/build/app/outputs/flutter-apk/app-debug.apk`
  - `voxmatrix-debug.apk`

### ADB install fails

- Ensure the device is connected:
  ```bash
  adb devices
  ```
- Reconnect wireless ADB:
  ```bash
  adb connect 100.98.138.106:36757
  ```

