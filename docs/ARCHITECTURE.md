# VoxMatrix Technical Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Devices                             │
├─────────────────────────────┬───────────────────────────────────┤
│     Android App             │          iOS App                  │
│  (Flutter + matrix_sdk)     │   (Flutter + matrix_sdk)          │
│                             │                                   │
│  ┌─────────────────────┐   │   ┌─────────────────────┐         │
│  │   UI Layer          │   │   │   UI Layer          │         │
│  │   (Flutter Widgets) │   │   │   (Flutter Widgets) │         │
│  ├─────────────────────┤   │   ├─────────────────────┤         │
│  │   Business Logic    │   │   │   Business Logic    │         │
│  │   (BLoC/Riverpod)   │   │   │   (BLoC/Riverpod)   │         │
│  ├─────────────────────┤   │   ├─────────────────────┤         │
│  │   Matrix SDK        │   │   │   Matrix SDK        │         │
│  │   (matrix_sdk)      │   │   │   (matrix_sdk)      │         │
│  ├─────────────────────┤   │   ├─────────────────────┤         │
│  │   Storage           │   │   │   Storage           │         │
│  │   (SQLite/Secure)   │   │   │   (Keychain/Secure) │         │
│  └─────────────────────┘   │   └─────────────────────┘         │
└─────────────────────────────┴───────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Matrix Federation                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│    ┌──────────────┐      ┌──────────────┐      ┌────────────┐  │
│    │   Dendrite   │◄────►│   Synapse    │◄────►│  Conduit   │  │
│    │  (Your Home) │      │ (Federation) │      │ (Other)    │  │
│    │              │      │              │      │            │  │
│    │  - PostgreSQL│      │  - PostgreSQL│      │  - SQLite  │  │
│    │  - Media Repo│      │  - Media Repo│      │            │  │
│    └──────────────┘      └──────────────┘      └────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌───────────┐   ┌───────────┐   ┌─────────────┐
            │   TURN    │   │  Sygnal   │   │  Well-known │
            │   Server  │   │  (Push)   │   │  Discovery  │
            │  (coturn) │   │           │   │             │
            └───────────┘   └───────────┘   └─────────────┘
```

---

## App Architecture (Flutter)

### Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Pages     │  │  Widgets    │  │   Theme/Styles      │  │
│  │  (Routes)   │  │ (Reusable)  │  │   (Material/Cupertino)│
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    Application Layer                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   BLoC      │  │  Use Cases  │  │   Repositories      │  │
│  │ (State Mgmt)│  │ (Business)  │  │   (Data Access)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │  Value Obj  │  │   Domain Events     │  │
│  │ (Models)    │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                     Data Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Matrix SDK  │  │   Local DB  │  │   Secure Storage    │  │
│  │  (matrix_   │  │  (sqflite)  │  │  (flutter_secure)   │  │
│  │   sdk)      │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Authentication Module

```dart
// Simplified structure
class AuthenticationManager {
  final MatrixClient client;
  final SecureStorage secureStorage;

  Future<void> login(String homeserver, String username, String password) async {
    // 1. Discover homeserver via .well-known
    // 2. Login via Matrix API
    // 3. Store access token securely
    // 4. Initialize E2EE
  }

  Future<void> logout() async {
    // 1. Clear local data
    // 2. Delete keys from secure storage
    // 3. Notify server
  }
}
```

### 2. Room/Chat Manager

```dart
class RoomManager {
  final MatrixClient client;
  final RoomRepository roomRepository;

  Stream<List<Room>> getRooms() {
    // Return paginated room list
    // Handle: invites, DMs, spaces, favorites
  }

  Stream<List<Event>> getMessages(String roomId) {
    // Pagination support
    // Offline cache
    // Timeline gaps handling
  }

  Future<void> sendMessage(String roomId, String content) async {
    // Handle local echo
    // Encrypt if E2EE enabled
    // Send to server
    // Handle send error
  }
}
```

### 3. E2EE Implementation (Olm/Megolm)

**Status**: ✅ Fully Implemented

The E2EE implementation uses the official `olm: ^2.0.3` library with Clean Architecture.

```dart
// Repository Interface (Domain Layer)
abstract class CryptoRepository {
  Future<Either<Failure, void>> initialize();
  Future<Either<Failure, String>> encryptMessage({
    required String roomId,
    required String plaintext,
  });
  Future<Either<Failure, String>> decryptMessage({
    required String roomId,
    required String ciphertext,
    required String senderKey,
    required String sessionId,
  });
  Future<Either<Failure, void>> verifyDevice({
    required String userId,
    required String deviceId,
    bool verified = true,
  });
}

// DataSources (Data Layer)
class OlmAccountDataSource {
  Future<Map<String, dynamic>> createAccount();
  Map<String, String> getIdentityKeys(); // Curve25519 & Ed25519
  String signJson(Map<String, dynamic> data);
}

class OlmSessionDataSource {
  Future<olm.Session> createOutboundSession({
    required String theirIdentityKey,
    required String theirOneTimeKey,
  });
  Future<String> decryptMessage({
    required olm.Session session,
    required int messageType,
    required String ciphertext,
  });
}

class MegolmSessionDataSource {
  Future<Map<String, dynamic>> createOutboundSession(String roomId);
  Future<String> encryptMessage({required String roomId, required String plaintext});
  Future<void> importInboundSession({
    required String roomId,
    required String sessionId,
    required String sessionKey,
    required String senderKey,
  });
}
```

**Key Features**:
- ✅ Olm account with Curve25519/Ed25519 key pairs
- ✅ Double Ratchet for 1:1 encryption
- ✅ Megolm AES-256 for group/room encryption
- ✅ Secure key storage (flutter_secure_storage)
- ✅ Device verification support

### 4. WebRTC Calling (LiveKit)

**Status**: ✅ Fully Implemented

The calling implementation uses `livekit_client: ^2.3.0` for production-ready WebRTC.

```dart
// Repository Interface (Domain Layer)
abstract class CallRepository {
  Future<Either<Failure, CallEntity>> createCall({
    required String roomId,
    required String calleeId,
    required bool isVideoCall,
  });
  Future<Either<Failure, void>> answerCall({required String callId, required String roomId});
  Future<Either<Failure, void>> hangupCall({required String callId, required String roomId});
  Stream<CallEntity> get incomingCallStream;
  Stream<CallEntity> get callStateStream;
}

// DataSources (Data Layer)
class LiveKitDataSource {
  Future<void> connect({required String wsUrl, required String token});
  Future<void> enableAudio();
  Future<void> enableVideo({bool facingMode = false});
  Future<void> setAudioEnabled(bool enabled);
  Future<void> setVideoEnabled(bool enabled);
  Future<void> switchCamera();
  List<RemoteParticipant> get remoteParticipants;
}

class MatrixCallSignalingDataSource {
  Future<void> sendInvite({
    required String roomId,
    required String callId,
    required String calleeId,
    required bool isVideoCall,
    required String liveKitRoom,
    required String liveKitToken,
  });
  Future<void> sendAnswer({...});
  Future<void> sendHangup({...});
  Stream<MatrixCallEvent> get incomingCalls;
}
```

**Key Features**:
- ✅ 1:1 voice and video calls
- ✅ LiveKit room management
- ✅ Matrix signaling (invite/answer/hangup)
- ✅ Camera switching (front/back)
- ✅ Mute/unmute controls
- ✅ Participant management

---

## Data Flow

### Message Send Flow

```
User Input
    │
    ▼
┌─────────────────┐
│  UI (TextField) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Message BLoC    │◄─────────────────────┐
└────────┬────────┘                      │
         │                              │
         ▼                              │
┌─────────────────┐                      │
│ Encryption Mgr  │                      │
│  (if E2EE)      │                      │
└────────┬────────┘                      │
         │                              │
         ▼                              │
┌─────────────────┐                      │
│ Matrix SDK      │                      │
│ (Event Build)   │                      │
└────────┬────────┘                      │
         │                              │
         ▼                              │
┌─────────────────┐                      │
│ Local Echo      │                      │
│ (Optimistic UI) │◄─────────────────────┘
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Network Queue   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Homeserver      │
│ (via API)       │
└─────────────────┘
         │
         ▼
   Remote Echo
         │
         ▼
┌─────────────────┐
│ Replace Local   │
│ Echo with Conf  │
└─────────────────┘
```

### Call Establishment Flow

```
Caller                        Callee
   │                             │
   │   m.call.invite             │
   │────────────────────────────►│
   │                             │
   │   (callee rings)            │
   │                             │
   │   m.call.answer             │
   │◄────────────────────────────│
   │                             │
   │   ICE candidates exchange   │
   │◄──────────────────────────►│
   │                             │
   │   WebRTC Connection         │
   │◄──────────────────────────►│
   │                             │
   │   (media stream active)     │
   │                             │
```

---

## Storage Architecture

### Local Database Schema

```sql
-- Rooms table
CREATE TABLE rooms (
  id TEXT PRIMARY KEY,
  name TEXT,
  avatar_url TEXT,
  topic TEXT,
  is_direct INTEGER DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  is_low_priority INTEGER DEFAULT 0,
  notification_count INTEGER DEFAULT 0,
  highlight_count INTEGER DEFAULT 0,
  last_message TEXT,
  last_message_ts INTEGER,
  unread_marker TEXT
);

-- Events table
CREATE TABLE events (
  event_id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  sender TEXT NOT NULL,
  type TEXT NOT NULL,
  content TEXT,
  origin_server_ts INTEGER,
  decrypted_content TEXT,
  transaction_id TEXT,
  local_echo_state TEXT, -- 'sending', 'sent', 'error'
  FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE INDEX events_room_id ON events(room_id);
CREATE INDEX events_ts ON events(origin_server_ts);

-- Devices table (E2EE)
CREATE TABLE devices (
  user_id TEXT,
  device_id TEXT,
  display_name TEXT,
  trust_level TEXT, -- 'verified', 'blocked', 'unset'
  keys TEXT,
  PRIMARY KEY (user_id, device_id)
);

-- Outbox (for offline queue)
CREATE TABLE outbox (
  id TEXT PRIMARY KEY,
  room_id TEXT,
  event_type TEXT,
  content TEXT,
  created_at INTEGER,
  retry_count INTEGER DEFAULT 0
);
```

### Secure Storage Items

```
Keychain / Keystore:
├── access_token
├── device_id
├── user_id
├── homeserver_url
├── olm_account_key
├── megolm_session_keys (per room)
├── cross_signing_keys
└── backup_key
```

---

## Server Architecture (Self-Hosted)

### Dendrite Deployment

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │  Dendrite    │  │   PostgreSQL │  │   coturn    │  │
│  │  :8008       │  │  :5432       │  │   :3478     │  │
│  │              │  │              │  │             │  │
│  │  - Client API│  │  - Matrix DB │  │  - TURN     │  │
│  │  - Federation│  │  - User Accts│  │  - STUN     │  │
│  │  - Sync      │  │              │  │  - TLS      │  │
│  └──────────────┘  └──────────────┘  └─────────────┘  │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │   Sygnal     │  │   Nginx      │  │   Caddy     │  │
│  │  :5000       │  │  :443        │  │   (TLS)     │  │
│  │              │  │              │  │             │  │
│  │  - Push GW   │  │  - Reverse   │  │  - Auto     │  │
│  │  - UnifiedPush│  │    Proxy    │  │    Certs    │  │
│  └──────────────┘  └──────────────┘  └─────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### docker-compose.yml (Draft)

```yaml
version: "3.8"

services:
  dendrite:
    image: matrixdotorg/dendrite-monolith:latest
    ports:
      - "8008:8008"
    volumes:
      - ./config:/etc/dendrite
      - ./data:/var/dendrite
    depends_on:
      - postgres
    environment:
      - DENDRITE_TLS_CERT=/etc/dendrite/cert.pem
      - DENDRITE_TLS_KEY=/etc/dendrite/key.pem

  postgres:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=dendrite
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=dendrite

  coturn:
    image: coturn/coturn:latest
    ports:
      - "3478:3478/tcp"
      - "3478:3478/udp"
      - "49152-49200:49152-49200/udp"
    volumes:
      - ./turnserver.conf:/etc/coturn/turnserver.conf
      - ./certs:/etc/coturn/certs

  sygnal:
    image: vectorim/sygnal:latest
    ports:
      - "5000:5000"
    volumes:
      - ./sygnal.yaml:/etc/sygnal/sygnal.yaml

volumes:
  postgres_data:
```

---

## Security Architecture

### End-to-End Encryption Flow

```
┌────────────────────────────────────────────────────────────┐
│                     Message Encryption                      │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Plaintext                                                 │
│      │                                                     │
│      ▼                                                     │
│  ┌─────────────────┐                                      │
│  │ Megolm Encrypt  │                                      │
│  │ (Room Key)      │                                      │
│  └────────┬────────┘                                      │
│           │                                                │
│           ▼                                                │
│  ┌─────────────────┐                                      │
│  │ Olm Encrypt     │                                      │
│  │ (Per Device)    │                                      │
│  └────────┬────────┘                                      │
│           │                                                │
│           ▼                                                │
│  Encrypted Event (m.room.encrypted)                        │
│           │                                                │
│           ▼                                                │
│  Send to Homeserver (Server can't read)                    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Device Verification

```
┌─────────────────┐         ┌─────────────────┐
│   Device A      │         │   Device B      │
│                 │         │                 │
│  ┌───────────┐  │         │  ┌───────────┐  │
│  │ Cross-    │  │         │  │ Cross-    │  │
│  │ Signing   │  │         │  │ Signing   │  │
│  │ Master    │  │         │  │ Master    │  │
│  │ Key       │  │         │  │ Key       │  │
│  └───────────┘  │         │  └───────────┘  │
│         │       │         │         │       │
│         │       │         │         │       │
│         └─────────────────┘         │       │
│               │                     │       │
│               ▼                     │       │
│  ┌──────────────────────┐           │       │
│  │  Interactive Verify  │           │       │
│  │  (SAS/Emoji Compare) │           │       │
│  └──────────────────────┘           │       │
│               │                     │       │
│               ▼                     ▼       │
│         ┌─────────────────┐         │       │
│         │   Trust Link    │◄────────┘       │
│         │   Established   │                 │
│         └─────────────────┘                 │
└─────────────────────────────────────────────┘
```

---

## Performance Optimization

### 1. Pagination Strategy

```dart
class TimelinePagination {
  static const int chunkSize = 50;

  Future<void> loadMore(String roomId) async {
    final cached = await localDb.getEvents(
      roomId,
      limit: chunkSize
    );

    if (cached.length < chunkSize) {
      // Fetch from server
      await _fetchFromServer(roomId);
    }
  }
}
```

### 2. Image Optimization

```dart
class ImageOptimizer {
  static const int thumbnailSize = 200;
  static const int previewSize = 800;

  Future<String> uploadThumbnail(File image) async {
    final thumb = await resize(image, thumbnailSize);
    return await matrixClient.uploadContent(thumb);
  }
}
```

### 3. Sync Loop Optimization

```dart
class SyncOptimizer {
  Duration syncInterval = Duration(seconds: 30);

  void adjustSync() {
    if (appInForeground) {
      syncInterval = Duration(seconds: 3);
    } else if (hasActiveCall) {
      syncInterval = Duration(seconds: 1);
    } else {
      syncInterval = Duration(minutes: 5);
    }
  }
}
```

---

## Dependencies

### Core Flutter Dependencies

```yaml
dependencies:
  # Matrix SDK
  matrix_sdk_flutter: ^1.0.0
  matrix_sdk: ^1.0.0

  # State Management
  flutter_bloc: ^8.1.0
  # OR
  riverpod: ^2.4.0

  # Storage
  sqflite: ^2.3.0
  flutter_secure_storage: ^9.0.0

  # Networking
  http: ^1.1.0
  connectivity_plus: ^5.0.0

  # WebRTC
  flutter_webrtc: ^0.9.47

  # UI
  flutter_svg: ^2.0.0
  cached_network_image: ^3.3.0
  flutter_markdown: ^0.6.0
  emoji_picker_flutter: ^1.6.0

  # Utilities
  path_provider: ^2.1.0
  shared_preferences: ^2.2.0
  permission_handler: ^11.0.0
  awesome_notifications: ^0.7.0

  # File Handling
  file_picker: ^6.1.0
  image_picker: ^1.0.0
  video_player: ^2.8.0
  audioplayers: ^5.2.0
```

---

*Last Updated: 2025-01-31*
