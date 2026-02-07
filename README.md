# VoxMatrix

A privacy‑focused Matrix client for Android and iOS with self‑hosted server support.

## Overview

VoxMatrix is a modern, secure Matrix client built with Flutter. It targets a clean UX with real‑time messaging, E2EE, and WebRTC calling. The app is designed for self‑hosted deployments and works well inside a Tailscale network.

## Current Capabilities

- Real‑time messaging with Matrix SDK sync
- E2EE via Olm/Megolm (Matrix SDK)
- WebRTC voice/video calls (flutter_webrtc)
- File sharing (basic)
- Dark‑mode focused UI refresh with gradients
- Direct messages and rooms
- Typing indicators and read markers

## Architecture

- **Flutter + Clean Architecture**
- **Matrix SDK** for sync, encryption, room state
- **DI** via `get_it` and `injectable`
- **Repositories** mediate between data sources and domain use cases
- **BLoC** for presentation state

## Repo Structure

- `app/` Flutter app
- `server/` Matrix server scripts and configs
- `docker/` Android build container
- `docs/` design and implementation notes

## Server (Tailscale) Setup

The project is configured to run Matrix Synapse without Caddy when on Tailscale.

### Homeserver

- **Homeserver URL**: `http://100.92.210.91:8008`
- **Server name**: `100.92.210.91`

### Running Synapse + Coturn (Tailscale)

If you need to start from scratch:

```bash
cd server
# Ensure .env is present if you use setup scripts
# Then run
./start-tailscale.sh
```

If compose is unreliable in your environment, these direct Docker commands are used:

```bash
docker run -d --name voxmatrix-synapse --restart unless-stopped \
  -p 100.92.210.91:8008:8008 \
  -v /home/xaf/Desktop/VoxMatrix/server/data/synapse:/data \
  -v /home/xaf/Desktop/VoxMatrix/server/synapse.tailscale.yaml:/data/homeserver.yaml:ro \
  -e SYNAPSE_SERVER_NAME=100.92.210.91 \
  -e SYNAPSE_REPORT_STATS=no \
  -e UID=1000 -e GID=1000 \
  matrixdotorg/synapse:latest

docker run -d --name voxmatrix-coturn --restart unless-stopped --network host \
  -v /home/xaf/Desktop/VoxMatrix/server/coturn/turnserver.tailscale.conf:/etc/coturn/turnserver.conf:ro \
  coturn/coturn:latest
```

### Admin + Test Accounts

- Admin: `admin` / `QvcQvc!4321`
- Test: `test` / `test`
- Test: `test2` / `test2`

User IDs:
- `@admin:100.92.210.91`
- `@test:100.92.210.91`
- `@test2:100.92.210.91`

## App Setup

### Install Dependencies

```bash
cd app
flutter pub get
```

### Build APK (Docker)

```bash
./docker/build-android.sh
```

APK output:
- `app/build/app/outputs/flutter-apk/app-debug.apk`
- Copied to `voxmatrix-debug.apk`

### Wireless ADB Install

```bash
adb connect 100.98.138.106:36757
adb install -r voxmatrix-debug.apk
```

## App Login

Use the same homeserver on both apps:

- `http://100.92.210.91:8008`

## Real‑Time Messaging & Unread

The app uses the Matrix SDK sync loop for real‑time events. Rooms and unread counts are refreshed from SDK state. Chat timelines subscribe to SDK events and refresh on sync.

## Troubleshooting

### Messages not appearing / unread not updating

1. Confirm both clients use the same homeserver URL.
2. Log out and log back in to force a clean SDK init.
3. Ensure the Matrix SDK database is initialized (requires sqflite).
4. Rebuild and reinstall APK after code changes.

### Common Runtime Errors

- `Matrix client not initialized`
  - Cause: SDK not initialized or init failed.
  - Fix: Check homeserver format, ensure DB initialization and re‑login.

- `You must provide a Database sqfliteDatabase for use on native`
  - Cause: Matrix SDK DB not backed by sqflite.
  - Fix: provide `sqflite.openDatabase` to `MatrixSdkDatabase`.

---

# Expanded Developer Documentation

This section is for other agents and future contributors. It explains the full architecture, implementation details, and the current production readiness plan.

## System Architecture

### Layers

- **Presentation**: Flutter UI + BLoC state management
- **Domain**: Entities + use cases
- **Data**: Repositories + data sources
- **Infra**: Matrix SDK, WebRTC, storage, and server

### Key Runtime Flow

1. User logs in via Matrix auth
2. Matrix SDK is initialized with sqflite‑backed DB
3. Background sync starts
4. Room list is sourced from SDK and refreshed on sync
5. Chat timelines subscribe to SDK events
6. Read markers are sent when incoming messages are viewed

## Matrix SDK Integration

### Initialization

- Matrix client initialization occurs in `MatrixClientService`.
- The SDK uses a SQLite database via `sqflite` (required for native).

### Database Provider

```dart
final dbPath = await sqflite.getDatabasesPath();
final sqliteDb = await sqflite.openDatabase('$dbPath/voxmatrix.sqlite');
final db = matrix.MatrixSdkDatabase('voxmatrix', database: sqliteDb);
await db.open();
```

### Sync Loop

- `client.backgroundSync = true` is enabled
- `client.onSync` is used to refresh room lists and chat timelines

### Room List

- Sourced from SDK `client.rooms`
- Uses `room.notificationCount` for unread
- Uses `room.lastEvent` for last message

### Messages

- Real‑time subscription via `client.onEvent`
- Decryption attempted for `m.room.encrypted` events
- Read markers sent on incoming messages in active chat

## Messaging Pipeline Details

### Chat Repository

- `getMessages` uses `room.getTimeline()` and decrypts if needed
- `getMessagesStream` listens to SDK event updates
- `markAsRead` sends read markers via `room.setReadMarker`

### Chat BLoC

- Loads history on open
- Subscribes to messages stream
- Refreshes on sync
- Sends read markers for incoming messages

### Rooms BLoC

- Loads rooms on open
- Refreshes on sync (debounced)
- Falls back to polling if SDK init fails

## E2EE

- Olm/Megolm via `olm`
- SDK handles key management and decryption
- Encryption status surfaced in crypto layer

## WebRTC

- `flutter_webrtc` for signaling and media
- Signaling uses Matrix events

## UI

- Dark‑mode centered palette
- Minimal gradients and clean spacing
- Reusable `AppBackground` widget

## Build & Release

### Android

- Docker build via `./docker/build-android.sh`
- Install via ADB

### iOS

- Not currently wired in CI
- Requires standard Flutter iOS build pipeline

## Testing Notes

- No automated tests are currently wired in CI
- Manual testing is required for:
  - login, sync, messaging
  - unread counts
  - read receipts
  - E2EE send/receive
  - call signaling

---

# Production‑Readiness Plan

This plan is the roadmap to deliver a complete, production‑grade messaging system.

## Phase 1: Reliability & Core Messaging

1. **Stable SDK Initialization**
   - Ensure single‑instance Matrix client
   - Robust DB initialization + migration
   - Persistent device ID across sessions

2. **Messaging Consistency**
   - SDK‑only timeline source
   - Ensure room list and chat use same SDK state
   - Proper pagination and scroll anchor
   - Guarantee new message ordering and de‑duplication

3. **Unread & Read Receipts**
   - Validate `notificationCount` behavior
   - Send read markers when chat is in view
   - Track read receipts per message

4. **Message Types**
   - Normalize rendering for `m.text`, `m.notice`, `m.emote`
   - Basic attachments: image, file, audio

## Phase 2: E2EE Hardening

1. **Device Trust UX**
   - Verification flows
   - Trusted/untrusted device status
   - Cross‑signing support

2. **Key Backup**
   - Secure key storage
   - Recovery flows

3. **Encrypted Search**
   - Local search index for decrypted messages

## Phase 3: Performance & UX

1. **Timeline Virtualization**
   - Lazy load messages
   - Efficient list rendering

2. **Offline Mode**
   - Cached rooms and messages
   - Queue outgoing messages

3. **Presence & Typing**
   - Presence updates
   - Typing indicators with expiry

## Phase 4: Calls & Media

1. **WebRTC Stabilization**
   - ICE reliability
   - Call state recovery
   - Background call handling

2. **Media Uploads**
   - Progress UI
   - Retry on failure

## Phase 5: Security & Privacy

1. **No analytics**
2. **Secure storage audit**
3. **Leak prevention**

## Phase 6: Server & Deployment

1. **Production Synapse config**
   - Postgres + Redis
   - Proper TURN config

2. **Backup & Restore**
   - Automated snapshots

3. **Monitoring**
   - Health checks
   - Log rotation

## Phase 7: QA & Release

1. **Automated Test Suite**
   - Unit tests for repositories
   - Integration tests for sync
   - UI smoke tests

2. **Release Pipeline**
   - CI for Android and iOS
   - Versioning and release notes

---

# Contribution Guide (Agents)

## How to Work in This Repo

1. Use `rg` for searches
2. Prefer editing via `apply_patch`
3. Rebuild APK with Docker for every functional change
4. Use wireless ADB for device validation

## Safe Update Checklist

- Update DI when constructor signatures change
- Rebuild after dependency updates
- Verify Matrix init in logcat when messaging changes

## Common Pitfalls

- Missing sqflite DB causes SDK init failure
- Async initializations need guarding
- Mixing HTTP and SDK in rooms causes stale state

---

# License

TBD
