# VoxMatrix E2EE & WebRTC Implementation Plan

## Executive Summary

**Current State**: 
- E2EE: Stub implementation (base64 encoding only)
- WebRTC: Stub implementation (no actual media)

**Goal**: Fully functional E2EE using Olm library and WebRTC calling using LiveKit

**Dependencies Already Present**:
- `olm: ^2.0.3` - Olm cryptographic library
- `livekit_client: ^2.3.0` - WebRTC client

**Estimated Timeline**: 2-3 weeks for core features

---

## Part 1: End-to-End Encryption (E2EE)

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ CryptoDevice │  │MegolmSession │  │RoomCryptoInfo│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         CryptoRepository (interface)                │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌────────────────────┐  ┌────────────────────────────┐    │
│  │CryptoLocalDataSrc  │  │ MatrixRemoteDataSource     │    │
│  │(Secure Storage)    │  │ (API calls)                │    │
│  └────────────────────┘  └────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                  Olm Library Integration                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ OlmAccount   │  │ OlmSession   │  │MegolmSession │      │
│  │ (Identity)   │  │ (1:1 E2EE)   │  │ (Group E2EE) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Phase 1.1: Olm Account Management (Week 1, Days 1-2)

**Objective**: Initialize and manage Olm account with proper key generation

**Implementation Steps**:
1. **Initialize Olm library** in `CryptoLocalDataSource`
   - Call `olm.init()` on app start
   - Handle library version checks
   
2. **Create OlmAccount wrapper**
   - Generate Curve25519 identity key
   - Generate Ed25519 signing key
   - Store in secure storage
   
3. **Device key management**
   - Generate device ID
   - Upload keys to Matrix server
   - Handle key rotation

**Files to Modify**:
- `lib/data/datasources/crypto_local_datasource.dart`
- `lib/data/repositories/crypto_repository_impl.dart`

**Key Methods**:
```dart
// Initialize Olm
await olm.init();
final account = olm.Account();
account.create();

// Get identity keys
final identityKeys = jsonDecode(account.identity_keys());
final curve25519Key = identityKeys['curve25519'];
final ed25519Key = identityKeys['ed25519'];

// Generate one-time keys for session creation
account.generate_one_time_keys(100);
final oneTimeKeys = jsonDecode(account.one_time_keys());
```

**Matrix API Integration**:
- Upload keys: `POST /_matrix/client/v3/keys/upload`
- Claim keys: `POST /_matrix/client/v3/keys/claim`
- Query keys: `POST /_matrix/client/v3/keys/query`

### Phase 1.2: Olm Session Management (Week 1, Days 3-4)

**Objective**: Implement 1:1 encryption using Olm double ratchet

**Implementation Steps**:
1. **Outbound session creation**
   - When sending first message to new device
   - Claim one-time key from server
   - Create session: `olm.Session.create_outbound_session()`
   
2. **Inbound session creation**
   - When receiving first encrypted message
   - Create session: `olm.Session.create_inbound_session()`
   
3. **Message encryption/decryption**
   - Encrypt: `session.encrypt(plaintext)` → OlmMessage
   - Decrypt: `session.decrypt(olmMessage)` → plaintext

**Session Storage**:
- Store pickled sessions in secure storage
- Key format: `olm_session_<userId>_<deviceId>`

**Files to Modify**:
- Add `lib/data/datasources/olm_session_datasource.dart`
- Update `lib/data/repositories/crypto_repository_impl.dart`

**Key Implementation**:
```dart
class OlmSessionDataSource {
  Future<OlmSession> createOutboundSession({
    required String theirIdentityKey,
    required String theirOneTimeKey,
  }) async {
    final session = olm.Session();
    session.create_outbound(
      olmAccount,
      theirIdentityKey,
      theirOneTimeKey,
    );
    return session;
  }
  
  Future<String> encryptMessage({
    required OlmSession session,
    required String plaintext,
  }) async {
    final message = session.encrypt(plaintext);
    return jsonEncode({
      'type': message.type, // 0 = prekey, 1 = message
      'body': message.body,
    });
  }
}
```

### Phase 1.3: Megolm Room Encryption (Week 1, Day 5 - Week 2, Day 2)

**Objective**: Implement group encryption for encrypted rooms

**Implementation Steps**:
1. **Megolm session creation**
   - Create new session for each room
   - Generate session key
   - Share with room participants via Olm
   
2. **Outbound group session**
   - Encrypt messages: `session.encrypt(plaintext)`
   - Include session ID and index in message
   
3. **Inbound group session**
   - Decrypt messages using session key
   - Handle session rotation

**Matrix Events**:
- `m.room.encrypted` - Encrypted message content
- `m.room_key` - Megolm session key sharing
- `m.forwarded_room_key` - Key forwarding for history

**Implementation**:
```dart
class MegolmSessionDataSource {
  Future<MegolmSession> createOutboundSession(String roomId) async {
    final session = olm.OutboundGroupSession();
    session.create();
    
    final sessionKey = session.session_key();
    final sessionId = session.session_id();
    
    // Share with all room members via Olm
    await _shareRoomKey(roomId, sessionKey, sessionId);
    
    return session;
  }
  
  Future<void> shareRoomKey({
    required String roomId,
    required String sessionKey,
    required String sessionId,
    required List<CryptoDevice> devices,
  }) async {
    // Encrypt session key for each device using Olm
    for (final device in devices) {
      final encrypted = await _encryptForDevice(sessionKey, device);
      await _sendRoomKeyEvent(roomId, device, encrypted);
    }
  }
}
```

### Phase 1.4: Device Verification (Week 2, Days 3-4)

**Objective**: Implement emoji/SAS verification and cross-signing

**Implementation Steps**:
1. **SAS (Short Authentication String) verification**
   - Generate emoji comparison
   - Implement verification flow
   - Mark devices as verified
   
2. **Cross-signing support**
   - Master key generation
   - Self-signing key
   - User-signing key

**Files to Modify**:
- `lib/presentation/crypto/bloc/crypto_bloc.dart`
- `lib/presentation/crypto/pages/verification_page.dart`

### Phase 1.5: Integration & Testing (Week 2, Day 5)

**Objective**: Wire everything together and test

**Integration Points**:
1. Message sending flow
   - Check if room is encrypted
   - Encrypt if needed
   - Send via Matrix API
   
2. Message receiving flow
   - Detect encrypted messages
   - Decrypt using appropriate session
   - Display plaintext

**Testing Strategy**:
- Unit tests for Olm operations
- Integration tests with test Matrix server
- Manual testing between two devices

---

## Part 2: WebRTC Calling with LiveKit

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ CallEntity   │  │ CallConfig   │  │IceCandidate  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          CallRepository (interface)                 │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            LiveKitDataSource                        │   │
│  │  - Room connection                                  │   │
│  │  - Track management                                 │   │
│  │  - Participant handling                             │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                  Signaling Layer                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │        MatrixCallSignaling                          │   │
│  │  - Send call invites via Matrix events              │   │
│  │  - Handle call events from sync                     │   │
│  │  - Exchange LiveKit tokens                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Phase 2.1: LiveKit Room Manager (Week 2, Days 1-2)

**Objective**: Set up LiveKit room connection infrastructure

**Implementation Steps**:
1. **Initialize LiveKit**
   - Set up audio configuration
   - Handle permissions
   
2. **Room connection**
   - Connect to LiveKit server
   - Handle connection state
   - Reconnection logic

**New Files**:
- `lib/data/datasources/livekit_datasource.dart`

**Key Implementation**:
```dart
class LiveKitDataSource {
  late Room _room;
  
  Future<void> connect({
    required String url,
    required String token,
  }) async {
    _room = Room();
    
    await _room.connect(url, token);
    
    // Listen to room events
    _room.addListener(_onRoomEvent);
  }
  
  Future<void> disconnect() async {
    await _room.disconnect();
  }
  
  void _onRoomEvent() {
    // Handle room state changes
    final participants = _room.remoteParticipants;
    final connectionState = _room.connectionState;
  }
}
```

### Phase 2.2: Audio/Video Track Management (Week 2, Days 3-4)

**Objective**: Manage local and remote media tracks

**Implementation Steps**:
1. **Local tracks**
   - Enable/disable microphone
   - Enable/disable camera
   - Switch camera (front/back)
   
2. **Remote tracks**
   - Subscribe to remote audio/video
   - Handle track publications
   
3. **Media rendering**
   - VideoTrackRenderer widget
   - Audio playback

**Key Implementation**:
```dart
class LiveKitDataSource {
  LocalAudioTrack? _audioTrack;
  LocalVideoTrack? _videoTrack;
  
  Future<void> enableAudio() async {
    _audioTrack = await LocalAudioTrack.createAudioTrack();
    await _room.localParticipant.publishAudioTrack(_audioTrack!);
  }
  
  Future<void> enableVideo() async {
    _videoTrack = await LocalVideoTrack.createCameraTrack();
    await _room.localParticipant.publishVideoTrack(_videoTrack!);
  }
  
  Future<void> disableAudio() async {
    await _audioTrack?.mute();
  }
  
  Future<void> disableVideo() async {
    await _videoTrack?.mute();
  }
  
  Future<void> switchCamera() async {
    await _videoTrack?.switchCamera();
  }
  
  Stream<RemoteParticipant> get remoteParticipants {
    return _room.remoteParticipants.values.toList().asStream();
  }
}
```

### Phase 2.3: Matrix Call Signaling (Week 3, Days 1-2)

**Objective**: Use Matrix events for call setup/teardown

**Implementation Steps**:
1. **Call invite**
   - Send `m.call.invite` event with LiveKit room URL and token
   - Include call type (audio/video)
   
2. **Call answer**
   - Send `m.call.answer` event
   - Connect to LiveKit room
   
3. **Call hangup**
   - Send `m.call.hangup` event
   - Disconnect from room

**New Files**:
- `lib/data/datasources/matrix_call_signaling_datasource.dart`

**Matrix Call Event Structure**:
```json
{
  "type": "m.call.invite",
  "content": {
    "call_id": "12345",
    "version": "1",
    "lifetime": 60000,
    "offer": {
      "type": "offer",
      "sdp": "...",
      "livekit_room": "room_123",
      "livekit_token": "jwt_token_here"
    }
  }
}
```

### Phase 2.4: Call Repository Integration (Week 3, Days 3-4)

**Objective**: Wire everything together in CallRepository

**Files to Modify**:
- `lib/data/repositories/call_repository_impl.dart`

**Integration Flow**:
1. User initiates call
2. Generate LiveKit room and token
3. Send Matrix invite event with LiveKit info
4. Connect to LiveKit room
5. Handle incoming calls
6. Manage call state

**Implementation**:
```dart
class CallRepositoryImpl implements CallRepository {
  final LiveKitDataSource _liveKitDataSource;
  final MatrixCallSignalingDataSource _signalingDataSource;
  
  @override
  Future<Either<Failure, CallEntity>> createCall({
    required String roomId,
    required String calleeId,
    required bool isVideoCall,
  }) async {
    try {
      // Generate LiveKit room and token
      final callId = _generateCallId();
      final liveKitInfo = await _generateLiveKitRoom(callId);
      
      // Send Matrix invite
      await _signalingDataSource.sendInvite(
        roomId: roomId,
        callId: callId,
        calleeId: calleeId,
        isVideoCall: isVideoCall,
        liveKitRoom: liveKitInfo.room,
        liveKitToken: liveKitInfo.token,
      );
      
      // Connect to LiveKit
      await _liveKitDataSource.connect(
        url: liveKitInfo.url,
        token: liveKitInfo.token,
      );
      
      // Enable media
      await _liveKitDataSource.enableAudio();
      if (isVideoCall) {
        await _liveKitDataSource.enableVideo();
      }
      
      return Right(CallEntity(
        callId: callId,
        roomId: roomId,
        state: CallState.outgoing,
        isVideoCall: isVideoCall,
        // ... other fields
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
```

### Phase 2.5: Call UI Integration (Week 3, Day 5)

**Objective**: Update call pages to use real WebRTC

**Files to Modify**:
- `lib/presentation/call/call_page.dart`
- `lib/presentation/call/widgets/video_view.dart`

**Key Changes**:
1. Replace stub video widgets with VideoTrackRenderer
2. Connect to CallRepository streams
3. Handle call state changes

---

## Implementation Order

### Week 1
- **Day 1-2**: Olm Account Management
- **Day 3-4**: Olm Session Management  
- **Day 5**: Megolm Session Setup

### Week 2
- **Day 1-2**: Megolm Room Encryption
- **Day 3-4**: Device Verification
- **Day 5**: E2EE Integration & Testing

### Week 3
- **Day 1-2**: LiveKit Room Setup + Matrix Signaling
- **Day 3-4**: Audio/Video Track Management
- **Day 5**: Call UI Integration & Testing

---

## Testing Strategy

### E2EE Tests
1. **Unit Tests**
   - Olm account creation
   - Session encryption/decryption
   - Megolm message encryption
   
2. **Integration Tests**
   - Send encrypted message
   - Receive and decrypt
   - Device verification flow
   
3. **Manual Tests**
   - Two-device message exchange
   - Group room encryption
   - Key rotation

### WebRTC Tests
1. **Unit Tests**
   - Room connection
   - Track management
   
2. **Integration Tests**
   - Call initiation
   - Call answer
   - Media streaming
   
3. **Manual Tests**
   - 1:1 audio call
   - 1:1 video call
   - Call quality under various network conditions

---

## Dependencies

### New Dependencies (if needed)
```yaml
dependencies:
  # Already present:
  # olm: ^2.0.3
  # livekit_client: ^2.3.0
  
  # May need:
  flutter_olm: ^1.0.0  # If olm needs wrapper
```

### Platform Setup

**Android** (already configured in manifest):
- Camera permission
- Microphone permission
- Internet permission

**iOS** (need to add to Info.plist):
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice calls</string>
```

---

## Risk Mitigation

### E2EE Risks
1. **Olm library compatibility** → Test on both platforms early
2. **Key storage security** → Use flutter_secure_storage (already in use)
3. **Performance with large rooms** → Implement session caching

### WebRTC Risks
1. **LiveKit server availability** → Allow fallback to standard WebRTC
2. **Network/firewall issues** → Implement TURN server (already configured)
3. **Battery consumption** → Optimize track subscriptions

---

## Success Criteria

✅ **E2EE Complete When**:
- Can send encrypted messages in E2EE rooms
- Can receive and decrypt messages from other clients
- Device verification flow works
- Keys are properly stored and rotated

✅ **WebRTC Complete When**:
- Can initiate audio call
- Can initiate video call  
- Can answer incoming calls
- Audio/video streams work bidirectionally
- Call controls (mute, video toggle, hangup) work
