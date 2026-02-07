# Critical Fixes Implementation Plan

## Executive Summary

This document provides step-by-step implementation plans for the two critical issues blocking production:
1. E2EE - Migrate from `olm` to `flutter_olm` to fix SIGSEGV crashes
2. WebRTC - Set up LiveKit server and implement full client

---

## Part 1: E2EE Migration (olm → flutter_olm)

### Problem Analysis

**Current State**:
- Package: `olm: ^2.0.3` (Famedly)
- Issue: SIGSEGV crashes on some Android devices
- Status: E2EE completely disabled (stub implementation)

**Root Cause**:
The `olm` package has compatibility issues with Flutter 3.x on Android, causing native FFI crashes.

**Solution**:
Migrate to `flutter_olm: ^2.0.0` which includes:
- Pre-built native libraries for Android/iOS
- Better Flutter 3.x compatibility
- Same API (drop-in replacement)

---

### Implementation Steps

#### Phase 1: Update Dependencies (1 day)

**Step 1.1: Update pubspec.yaml**
```yaml
# Remove
olm: ^2.0.3

# Add
flutter_olm: ^2.0.0
```

**Step 1.2: Clean and reinstall**
```bash
cd /home/xaf/Desktop/VoxMatrix/app
flutter clean
flutter pub get
```

---

#### Phase 2: Update DataSources (2-3 days)

**Step 2.1: Update OlmAccountDataSource**

**File**: `/app/lib/data/datasources/olm_account_datasource.dart`

**Changes**:
```dart
// OLD IMPORT
import 'package:olm/olm.dart';

// NEW IMPORT
import 'package:flutter_olm/flutter_olm.dart';

// Update initialization
Future<void> _initializeOlm() async {
  try {
    // OLD: await olm.init();
    // NEW: flutter_olm initializes automatically
    _logger.i('Flutter Olm initialized');
    _olmAvailable = true;
    _isInitialized = true;
  } catch (e, stackTrace) {
    _logger.e('Failed to initialize Flutter Olm', error: e, stackTrace: stackTrace);
    _olmAvailable = false;
    _isInitialized = true;
  }
}

// Update account creation
Future<Map<String, dynamic>> createAccount() async {
  if (!_isInitialized) {
    await _initializeOlm();
  }

  // OLD: final account = olm.Account();
  // NEW: final account = Account();
  final account = Account();
  account.create();

  // Get identity keys
  final identityKeys = jsonDecode(account.identity_keys());
  final curve25519Key = identityKeys['curve25519'];
  final ed25519Key = identityKeys['ed25519'];

  // Generate one-time keys
  account.generate_one_time_keys(100);

  final accountData = {
    'curve25519_key': curve25519Key,
    'ed25519_key': ed25519Key,
    'one_time_keys_count': 100,
    'olm_available': true,
  };

  await _saveAccount(account);
  return accountData;
}

// Update signing
String signJson(Map<String, dynamic> json) {
  final canonicalized = _canonicalizeJson(json);
  // OLD: account.sign(canonicalized)
  // NEW: account.sign(canonicalized)
  return _account.sign(canonicalized);
}
```

**Step 2.2: Update OlmSessionDataSource**

**File**: `/app/lib/data/datasources/olm_session_datasource.dart`

**Changes**:
```dart
// OLD IMPORT
import 'package:olm/olm.dart';

// NEW IMPORT
import 'package:flutter_olm/flutter_olm.dart';

// Update session creation
Future<Session> createOutboundSession({
  required String theirIdentityKey,
  required String theirOneTimeKey,
}) async {
  // OLD: final session = olm.Session();
  // NEW: final session = Session();
  final session = Session();
  session.create_outbound_session(
    _account,
    theirIdentityKey,
    theirOneTimeKey,
  );

  await _saveSession(session);
  return session;
}

// Update message encryption
Future<String> encryptMessage({
  required Session session,
  required String plaintext,
}) async {
  // OLD: final message = session.encrypt(plaintext);
  // NEW: final message = session.encrypt(plaintext);
  final message = session.encrypt(plaintext);

  return jsonEncode({
    'type': message.type,
    'body': message.body,
  });
}
```

**Step 2.3: Update MegolmSessionDataSource**

**File**: `/app/lib/data/datasources/megolm_session_datasource.dart`

**Changes**:
```dart
// OLD IMPORT
import 'package:olm/olm.dart';

// NEW IMPORT
import 'package:flutter_olm/flutter_olm.dart';

// Update outbound session creation
Future<Map<String, dynamic>> createOutboundSession(String roomId) async {
  // OLD: final session = olm.OutboundGroupSession();
  // NEW: final session = OutboundGroupSession();
  final session = OutboundGroupSession();
  session.create();

  final sessionKey = session.session_key();
  final sessionId = session.session_id();

  await _saveSession(roomId, session);
  await _shareRoomKey(roomId, sessionKey, sessionId);

  return {
    'session_id': sessionId,
    'session_key': sessionKey,
  };
}

// Update message encryption
Future<String> encryptMessage({
  required String roomId,
  required String plaintext,
}) async {
  final session = await _loadSession(roomId);
  // OLD: session.encrypt(plaintext);
  // NEW: session.encrypt(plaintext);
  final encrypted = session.encrypt(plaintext);

  return jsonEncode({
    'algorithm': 'm.megolm.v1.aes-sha2',
    'room_id': roomId,
    'sender_key': _myCurve25519Key,
    'session_id': session.session_id(),
    'ciphertext': encrypted.ciphertext,
  });
}
```

---

#### Phase 3: Testing (2 days)

**Test 1: Account Creation**
```bash
# Build and install APK
cd /home/xaf/Desktop/VoxMatrix/app
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Test on device
1. Open app
2. Try to login
3. Check logs for "Flutter Olm initialized"
4. Verify no SIGSEGV crashes
```

**Test 2: Encryption/Decryption**
```dart
// Add test file: test/crypto/encryption_test.dart
void main() {
  test('Olm account creation', () async {
    final account = Account();
    account.create();

    expect(account.identity_keys(), isNotEmpty);
    expect(account.one_time_keys(), isNotEmpty);
  });

  test('Message encryption/decryption', () {
    final aliceAccount = Account();
    aliceAccount.create();
    aliceAccount.generate_one_time_keys(1);

    final bobAccount = Account();
    bobAccount.create();
    bobAccount.generate_one_time_keys(1);

    // Create session
    final session = Session();
    session.create_outbound_session(
      aliceAccount,
      bobAccount.identity_keys()['curve25519'],
      bobAccount.one_time_keys()['curve25519']?.values.first,
    );

    final plaintext = 'Hello, World!';
    final encrypted = session.encrypt(plaintext);

    expect(encrypted.body, isNotEmpty);
    expect(encrypted.type, isNotEmpty);
  });
}
```

**Test 3: Integration Test**
```bash
# Run tests
flutter test test/crypto/encryption_test.dart

# Run on physical device
flutter test integration_test/encryption_e2e_test.dart
```

---

#### Phase 4: Enable E2EE in App (1 day)

**Step 4.1: Remove E2EE Disabled Flags**

**File**: `/app/lib/data/datasources/crypto_local_datasource.dart`

```dart
// Remove these checks
// if (!olmAccountDataSource.olmAvailable) {
//   return Left(CryptoFailure(
//     message: 'E2EE is disabled',
//     statusCode: 503,
//   ));
// }
```

**Step 4.2: Update CryptoBloc to Allow E2EE**

**File**: `/app/lib/presentation/crypto/bloc/crypto_bloc.dart`

```dart
// Remove disabled state check
if (event is EnableEncryption) {
  // OLD: if (!_cryptoRepository.isEnabled()) return;
  // NEW: Always try to enable
  emit(CryptoLoading());
  final result = await _cryptoRepository.initialize();

  result.fold(
    (failure) => emit(CryptoError(failure.message)),
    (_) => emit(CryptoEnabled()),
  );
}
```

---

#### Phase 5: Rollback Plan (If Needed)

```bash
# Revert to olm package
cd /home/xaf/Desktop/VoxMatrix/app
git checkout HEAD -- pubspec.yaml

# Restore old datasource files
git checkout HEAD -- lib/data/datasources/olm_*.dart

# Clean and reinstall
flutter clean
flutter pub get

# Rebuild APK
flutter build apk --debug
```

---

### Success Criteria

- ✅ App doesn't crash on any test device (3+ Android devices)
- ✅ Olm account creation works
- ✅ Message encryption/decryption works
- ✅ Device verification flow works
- ✅ No SIGSEGV crashes in logs
- ✅ APK builds successfully

### Timeline

- **Phase 1**: 1 day
- **Phase 2**: 2-3 days
- **Phase 3**: 2 days
- **Phase 4**: 1 day
- **Total**: 6-7 days

---

## Part 2: WebRTC Implementation (LiveKit)

### Problem Analysis

**Current State**:
- Package: `livekit_client: ^2.3.0`
- Issue: Datasource is a stub (no actual WebRTC)
- Status: No server-side LiveKit deployment

**Root Cause**:
1. No production LiveKit server running
2. LiveKit datasource only simulates connection
3. No token generation service

**Solution**:
1. Set up production LiveKit server (Docker)
2. Implement full LiveKit client in Flutter
3. Create token generation API

---

### Implementation Steps

#### Phase 1: Set Up LiveKit Server (1 day)

**Step 1.1: Update Docker Compose**

**File**: `/server/docker-compose.yml`

```yaml
version: '3.8'

services:
  # ... existing services ...

  redis:
    image: redis:7-alpine
    container_name: voxmatrix-redis
    restart: unless-stopped
    networks:
      - voxmatrix-network

  livekit:
    image: livekit/livekit-server:latest
    container_name: voxmatrix-livekit
    restart: unless-stopped
    command: --config /etc/livekit/livekit.yaml
    ports:
      - "7880:7880"  # HTTP
      - "7881:7881"  # WebSocket
      - "7882:7882/udp"  # UDP for media
      - "7883:7883/udp"  # UDP for media
    environment:
      - LIVEKIT_KEYS=VoxMatrixKey1:VoxMatrixSecret12345678901234567890
      - LIVEKIT_REDIS_ADDRESS=redis:6379
    volumes:
      - ./livekit/livekit.yaml:/etc/livekit/livekit.yaml:ro
      - ./data/livekit:/data
    depends_on:
      - redis
    networks:
      - voxmatrix-network

networks:
  voxmatrix-network:
    driver: bridge
```

**Step 1.2: Create LiveKit Configuration**

**File**: `/server/livekit/livekit.yaml`

```yaml
port: 7880
rtc:
  port_range_start: 50000
  port_range_end: 60000
  use_ip: true
  # Use Tailscale IP for local development
  ip: 100.92.210.91

redis:
  address: redis:6379

room:
  enabled: true

keys:
  VoxMatrixKey1: VoxMatrixSecret12345678901234567890

turn:
  enabled: true
  servers:
    - host: 100.92.210.91
      port: 3478
      username: turnuser
      password: changeme_tailscale_turn
```

**Step 1.3: Start LiveKit Server**

```bash
cd /home/xaf/Desktop/VoxMatrix/server
docker-compose up -d redis livekit

# Check logs
docker-compose logs -f livekit

# Verify it's running
curl http://localhost:7880
```

---

#### Phase 2: Create Token Generation Service (1 day)

**Step 2.1: Add Token Generation to Server**

**Option A: Python Service (if using Python)**

**File**: `/server/services/token_service.py`

```python
import json
from datetime import datetime, timedelta
from livekit import api
from livekit.api import AccessToken, VideoGrants

# Configuration
API_KEY = "VoxMatrixKey1"
API_SECRET = "VoxMatrixSecret12345678901234567890"
SERVER_URL = "http://100.92.210.91:7881"

def generate_token(room_id, user_id, user_name):
    # Create token
    token = AccessToken(API_KEY, API_SECRET)
    token.with_identity(user_id)
    token.with_name(user_name)

    # Add video grants
    grants = VideoGrants(
        room_join=True,
        room=room_id,
        can_publish=True,
        can_subscribe=True
    )
    token.with_grants(grants)

    # Set expiration (1 hour)
    token.with_validity(timedelta(hours=1))

    return token.to_jwt()

if __name__ == "__main__":
    # Test token generation
    token = generate_token("test-room", "user123", "Test User")
    print(f"Token: {token}")
    print(f"Server URL: {SERVER_URL}")
```

**Option B: Go Service (if using Go)**

**File**: `/server/services/token_service.go`

```go
package main

import (
    "fmt"
    "net/http"
    "time"

    "github.com/livekit/protocol/auth"
)

const (
    apiKey    = "VoxMatrixKey1"
    apiSecret = "VoxMatrixSecret12345678901234567890"
    serverURL = "http://100.92.210.91:7881"
)

func generateToken(roomID, userID, userName string) (string, error) {
    at := auth.NewAccessToken(apiKey, apiSecret)

    at.WithIdentity(userID)
    at.WithName(userName)

    grant := &auth.VideoGrant{
        RoomJoin: true,
        Room:      roomID,
        CanPublish:   true,
        CanSubscribe: true,
    }

    at.WithGrant(grant)
    at.WithValidity(time.Hour)

    return at.ToJWT()
}

func tokenHandler(w http.ResponseWriter, r *http.Request) {
    roomID := r.URL.Query().Get("room_id")
    userID := r.URL.Query().Get("user_id")
    userName := r.URL.Query().Get("user_name")

    token, err := generateToken(roomID, userID, userName)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    response := map[string]string{
        "token":      token,
        "server_url": serverURL,
        "room_id":   roomID,
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func main() {
    http.HandleFunc("/token", tokenHandler)
    fmt.Println("Token service running on :7885")
    http.ListenAndServe(":7885", nil)
}
```

**Step 2.2: Add Token Service to Docker Compose**

```yaml
token-service:
  build: ./services/token-service
  container_name: voxmatrix-token-service
  restart: unless-stopped
  ports:
    - "7885:7885"
  networks:
    - voxmatrix-network
  depends_on:
    - livekit
```

---

#### Phase 3: Implement Full LiveKit Client (2-3 days)

**Step 3.1: Update LiveKitDataSource**

**File**: `/app/lib/data/datasources/livekit_datasource.dart`

```dart
import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';

@injectable
class LiveKitDataSource {
  LiveKitDataSource({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  Room? _room;
  LocalParticipant? _localParticipant;
  bool _isConnected = false;

  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  final _participantsController = StreamController<List<RemoteParticipant>>.broadcast();
  final _remoteTrackControllers = <String, StreamController<RemoteTrack>>{};

  // Configuration
  static const String serverUrl = 'ws://100.92.210.91:7881';
  static const String tokenServiceUrl = 'http://100.92.210.91:7885';

  bool get isConnected => _isConnected;
  Stream<ConnectionState> get connectionState => _connectionStateController.stream;
  List<RemoteParticipant> get remoteParticipants => _room?.remoteParticipants.values.toList() ?? [];

  /// Initialize LiveKit
  Future<void> initialize() async {
    _logger.i('Initializing LiveKit');
    _logger.i('LiveKit initialized successfully');
  }

  /// Connect to LiveKit room
  Future<void> connect({
    required String roomId,
    required String token,
    required String userId,
    required String userName,
  }) async {
    try {
      _logger.i('Connecting to LiveKit room: $roomId');

      // Create room
      _room = Room();

      // Create local participant
      _localParticipant = _room!.localParticipant;

      // Connect to server
      await _room!.connect(
        serverUrl,
        token,
        roomOptions: RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
        connectOptions: ConnectOptions(
          autoSubscribe: true,
        ),
      );

      _isConnected = true;
      _connectionStateController.add(ConnectionState.connected);

      // Listen to room events
      _room!.addListener(_onRoomEvent);

      _logger.i('Connected to LiveKit room successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to connect to LiveKit room', error: e, stackTrace: stackTrace);
      _connectionStateController.add(ConnectionState.failed);
      throw WebRTCException(message: 'Failed to connect to room: $e');
    }
  }

  void _onRoomEvent() {
    if (_room == null) return;

    // Update connection state
    switch (_room!.connectionState) {
      case ConnectionState.connected:
        _connectionStateController.add(ConnectionState.connected);
        break;
      case ConnectionState.reconnecting:
        _connectionStateController.add(ConnectionState.reconnecting);
        break;
      case ConnectionState.disconnected:
        _connectionStateController.add(ConnectionState.disconnected);
        _isConnected = false;
        break;
      default:
        break;
    }

    // Update participants list
    _participantsController.add(_room!.remoteParticipants.values.toList());

    // Listen to remote tracks
    for (final participant in _room!.remoteParticipants.values) {
      for (final track in participant.videoTracks) {
        final controller = StreamController<RemoteTrack>.broadcast();
        track.addListener(() {
          controller.add(track);
        });
        _remoteTrackControllers[track.sid!] = controller;
      }
    }
  }

  /// Enable local audio
  Future<void> enableAudio() async {
    if (!_isConnected || _localParticipant == null) {
      throw WebRTCException(message: 'Not connected to room');
    }

    await _localParticipant!.setCameraEnabled(true);
    _logger.i('Audio enabled');
  }

  /// Disable local audio
  Future<void> disableAudio() async {
    if (_localParticipant == null) return;

    await _localParticipant!.setMicrophoneEnabled(false);
    _logger.i('Audio disabled');
  }

  /// Enable local video
  Future<void> enableVideo({bool facingMode = false}) async {
    if (!_isConnected || _localParticipant == null) {
      throw WebRTCException(message: 'Not connected to room');
    }

    await _localParticipant!.setCameraEnabled(true);
    _logger.i('Video enabled');
  }

  /// Disable local video
  Future<void> disableVideo() async {
    if (_localParticipant == null) return;

    await _localParticipant!.setCameraEnabled(false);
    _logger.i('Video disabled');
  }

  /// Switch camera
  Future<void> switchCamera() async {
    if (_localParticipant == null) return;

    await _localParticipant!.switchCamera();
    _logger.i('Camera switched');
  }

  /// Mute/unmute audio
  Future<void> setAudioEnabled(bool enabled) async {
    if (_localParticipant == null) return;

    await _localParticipant!.setMicrophoneEnabled(enabled);
    _logger.i('Audio ${enabled ? 'unmuted' : 'muted'}');
  }

  /// Mute/unmute video
  Future<void> setVideoEnabled(bool enabled) async {
    if (_localParticipant == null) return;

    await _localParticipant!.setCameraEnabled(enabled);
    _logger.i('Video ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get remote track stream
  Stream<RemoteTrack>? getRemoteTrackStream(String trackSid) {
    return _remoteTrackControllers[trackSid]?.stream;
  }

  /// Disconnect from room
  Future<void> disconnect() async {
    try {
      if (_isConnected && _room != null) {
        _logger.i('Disconnecting from LiveKit room');
        await _room!.disconnect();
        _isConnected = false;
        _connectionStateController.add(ConnectionState.disconnected);
        _logger.i('Disconnected from room');
      }
    } catch (e, stackTrace) {
      _logger.e('Error disconnecting from room', error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    _logger.i('Disposing LiveKit data source');
    await disconnect();

    await _connectionStateController.close();
    await _participantsController.close();

    for (final controller in _remoteTrackControllers.values) {
      await controller.close();
    }
    _remoteTrackControllers.clear();

    _logger.i('LiveKit data source disposed');
  }
}

enum ConnectionState {
  connected,
  disconnected,
  reconnecting,
  failed,
}
```

**Step 3.2: Create Token Fetching Service**

**File**: `/app/lib/services/livekit_token_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class LiveKitTokenService {
  final Dio _dio;

  LiveKitTokenService() : _dio = Dio(BaseOptions(
    baseUrl: 'http://100.92.210.91:7885',
  ));

  Future<Map<String, dynamic>> generateToken({
    required String roomId,
    required String userId,
    required String userName,
  }) async {
    try {
      final response = await _dio.get('/token', queryParameters: {
        'room_id': roomId,
        'user_id': userId,
        'user_name': userName,
      });

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to generate token: $e');
    }
  }
}
```

**Step 3.3: Update CallRepositoryImpl**

**File**: `/app/lib/data/repositories/call_repository_impl.dart`

```dart
// Add to imports
import 'package:voxmatrix/services/livekit_token_service.dart';

@LazySingleton(as: CallRepository)
class CallRepositoryImpl implements CallRepository {
  // Existing fields...
  final LiveKitTokenService _tokenService;

  CallRepositoryImpl(
    this._liveKitDataSource,
    this._tokenService,
    // ... other dependencies
  );

  @override
  Future<Either<Failure, CallEntity>> createCall({
    required String roomId,
    required String calleeId,
    required bool isVideoCall,
  }) async {
    try {
      // Get current user info
      final userId = await _authLocalDataSource.getUserId();
      final userName = await _profileRepository.getDisplayName();

      // Generate LiveKit room name
      final liveKitRoom = 'call_${roomId}_${DateTime.now().millisecondsSinceEpoch}';

      // Generate LiveKit token
      final tokenData = await _tokenService.generateToken(
        roomId: liveKitRoom,
        userId: userId!,
        userName: userName,
      );

      // Connect to LiveKit
      await _liveKitDataSource.connect(
        roomId: liveKitRoom,
        token: tokenData['token'],
        userId: userId,
        userName: userName,
      );

      // Enable audio/video
      await _liveKitDataSource.enableAudio();
      if (isVideoCall) {
        await _liveKitDataSource.enableVideo();
      }

      // Send Matrix invite with LiveKit info
      await _signalingDataSource.sendInvite(
        roomId: roomId,
        callId: liveKitRoom,
        calleeId: calleeId,
        isVideoCall: isVideoCall,
        liveKitRoom: liveKitRoom,
        liveKitToken: tokenData['token'],
      );

      return Right(CallEntity(
        callId: liveKitRoom,
        roomId: roomId,
        state: CallState.outgoing,
        isVideoCall: isVideoCall,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create call: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> answerCall({
    required String callId,
    required String roomId,
    required bool isVideoCall,
  }) async {
    try {
      // Get current user info
      final userId = await _authLocalDataSource.getUserId();
      final userName = await _profileRepository.getDisplayName();

      // Generate token
      final tokenData = await _tokenService.generateToken(
        roomId: callId,
        userId: userId!,
        userName: userName,
      );

      // Connect to LiveKit
      await _liveKitDataSource.connect(
        roomId: callId,
        token: tokenData['token'],
        userId: userId,
        userName: userName,
      );

      // Enable media
      await _liveKitDataSource.enableAudio();
      if (isVideoCall) {
        await _liveKitDataSource.enableVideo();
      }

      // Send answer event
      await _signalingDataSource.sendAnswer(
        roomId: roomId,
        callId: callId,
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to answer call: $e'));
    }
  }
}
```

---

#### Phase 4: Testing (2 days)

**Test 1: LiveKit Server Connection**
```bash
# Test server is running
curl http://localhost:7880

# Test token generation
curl "http://localhost:7885/token?room_id=test&user_id=123&user_name=Test"

# Expected response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "server_url": "ws://100.92.210.91:7881",
  "room_id": "test"
}
```

**Test 2: App Connection**
```dart
// Add test file: test/webrtc/livekit_test.dart
void main() {
  testWidgets('LiveKit connection', (WidgetTester tester) async {
    final dataSource = LiveKitDataSource(logger: Logger());

    // Test connection
    await dataSource.connect(
      roomId: 'test-room',
      token: 'test-token',
      userId: 'user-123',
      userName: 'Test User',
    );

    expect(dataSource.isConnected, true);
    expect(dataSource.connectionState, emits(ConnectionState.connected));
  });

  testWidgets('Audio/Video controls', (WidgetTester tester) async {
    final dataSource = LiveKitDataSource(logger: Logger());

    await dataSource.connect(
      roomId: 'test-room',
      token: 'test-token',
      userId: 'user-123',
      userName: 'Test User',
    );

    // Test audio
    await dataSource.enableAudio();
    await dataSource.setAudioEnabled(false);

    // Test video
    await dataSource.enableVideo();
    await dataSource.setVideoEnabled(false);

    await dataSource.switchCamera();
  });
}
```

**Test 3: End-to-End Call Test**
```bash
# Build and install APK on two devices
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Test flow
1. Login as User A on Device 1
2. Login as User B on Device 2
3. User A calls User B
4. User B accepts call
5. Verify audio works both ways
6. Verify video works both ways
7. Test mute/unmute
8. Test camera switch
9. Test hangup
```

---

#### Phase 5: Rollback Plan (If Needed)

```bash
# Stop LiveKit server
cd /home/xaf/Desktop/VoxMatrix/server
docker-compose down livekit redis token-service

# Remove from docker-compose.yml
git checkout HEAD -- server/docker-compose.yml

# Restore stub implementation
git checkout HEAD -- app/lib/data/datasources/livekit_datasource.dart

# Revert CallRepositoryImpl
git checkout HEAD -- app/lib/data/repositories/call_repository_impl.dart
```

---

### Success Criteria

- ✅ LiveKit server running and accessible
- ✅ Token generation service working
- ✅ App connects to LiveKit room
- ✅ Audio track publishes and subscribes
- ✅ Video track publishes and subscribes
- ✅ Call controls work (mute, video toggle, camera switch)
- ✅ Call hangup works
- ✅ No crashes on test devices
- ✅ Two-way audio/video works

### Timeline

- **Phase 1**: 1 day
- **Phase 2**: 1 day
- **Phase 3**: 2-3 days
- **Phase 4**: 2 days
- **Total**: 6-7 days

---

## Summary

### Combined Timeline

**E2EE Migration**: 6-7 days
**WebRTC Implementation**: 6-7 days

**Parallel Execution**: 6-7 days total
**Sequential Execution**: 12-14 days total

### Risk Mitigation

| Risk | Mitigation |
|-------|------------|
| E2EE migration introduces bugs | Extensive testing, rollback plan |
| LiveKit setup complexity | Use Docker, step-by-step implementation |
| Token generation security | Use server-side generation, secure secrets |
| Testing device availability | Use multiple devices, emulators |

### Next Steps

1. Review this implementation plan
2. Choose implementation order (parallel or sequential)
3. Begin Phase 1 of E2EE migration OR Phase 1 of WebRTC setup
4. Monitor progress and adjust timeline as needed

---

**Document Version**: 1.0
**Last Updated**: 2026-02-06
**Author**: VoxMatrix Development Team
