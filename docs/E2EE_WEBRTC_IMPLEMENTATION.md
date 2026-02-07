# E2EE & WebRTC Implementation Documentation

## Overview

This document describes the implementation of End-to-End Encryption (E2EE) and WebRTC calling in VoxMatrix.

**Last Updated**: 2026-02-02
**Implementation Status**: Complete (Ready for Testing)

---

## E2EE Implementation

### Architecture

The E2EE implementation uses the Olm cryptographic library to provide:
- Device identity key management (Curve25519 & Ed25519)
- 1:1 message encryption using Olm Double Ratchet
- Group/room encryption using Megolm
- Device verification and trust management

### Components

#### 1. OlmAccountDataSource (`lib/data/datasources/olm_account_datasource.dart`)
- Manages device identity keys
- Generates and stores Curve25519 and Ed25519 keys
- Handles one-time key generation for session creation
- Signs JSON data with Ed25519 key

**Key Methods:**
```dart
Future<Map<String, dynamic>> createAccount()
Map<String, String> getIdentityKeys()
String signJson(Map<String, dynamic> data)
```

#### 2. OlmSessionDataSource (`lib/data/datasources/olm_session_datasource.dart`)
- Creates outbound Olm sessions for sending encrypted messages
- Creates inbound Olm sessions from pre-key messages
- Encrypts/decrypts messages using Olm Double Ratchet
- Persists sessions to secure storage

**Key Methods:**
```dart
Future<olm.Session> createOutboundSession({
  required String theirDeviceId,
  required String theirIdentityKey,
  required String theirOneTimeKey,
})

Future<String> decryptMessage({
  required olm.Session session,
  required int messageType,
  required String ciphertext,
})
```

#### 3. MegolmSessionDataSource (`lib/data/datasources/megolm_session_datasource.dart`)
- Manages outbound group sessions for room encryption
- Imports inbound sessions from room key events
- Encrypts room messages using Megolm AES-256
- Decrypts received room messages

**Key Methods:**
```dart
Future<Map<String, dynamic>> createOutboundSession(String roomId)
Future<String> encryptMessage({required String roomId, required String plaintext})
Future<void> importInboundSession({
  required String roomId,
  required String sessionId,
  required String sessionKey,
  required String senderKey,
})
```

#### 4. CryptoRepositoryImpl (`lib/data/repositories/crypto_repository_impl.dart`)
- High-level repository coordinating all E2EE operations
- Implements Matrix E2EE protocol
- Manages device verification and trust
- Handles room key sharing

**Key Methods:**
```dart
Future<Either<Failure, String>> encryptMessage({
  required String roomId,
  required String plaintext,
})

Future<Either<Failure, String>> decryptMessage({
  required String roomId,
  required String ciphertext,
  required String senderKey,
  required String sessionId,
})
```

### Usage Flow

#### Sending Encrypted Message:
1. Check if room is encrypted
2. Get or create Megolm outbound session
3. Encrypt message content
4. Build Matrix `m.room.encrypted` event
5. Send to server

#### Receiving Encrypted Message:
1. Detect `m.room.encrypted` event
2. Extract ciphertext, session ID, and sender key
3. Look up or import Megolm inbound session
4. Decrypt message
5. Parse JSON content

### Security Considerations

- All keys stored in `flutter_secure_storage` (encrypted keychain/keystore)
- Sessions are pickled and encrypted before storage
- One-time keys are rotated regularly
- Megolm sessions rotate after message count or time limits
- Device verification required for trusted encryption

---

## WebRTC Implementation

### Architecture

The WebRTC implementation uses LiveKit SDK for:
- Room-based audio/video calls
- Screen sharing
- Participant management
- Connection quality monitoring

### Components

#### 1. LiveKitDataSource (`lib/data/datasources/livekit_datasource.dart`)
- Manages LiveKit room connection
- Handles audio/video track publishing
- Manages remote participant subscriptions
- Provides connection state streams

**Key Methods:**
```dart
Future<void> connect({required String wsUrl, required String token})
Future<void> enableAudio()
Future<void> enableVideo({bool facingMode = false})
Future<void> setAudioEnabled(bool enabled)
Future<void> setVideoEnabled(bool enabled)
Future<void> switchCamera()
```

#### 2. MatrixCallSignalingDataSource (`lib/data/datasources/matrix_call_signaling_datasource.dart`)
- Sends Matrix call events (invite, answer, hangup)
- Receives and processes incoming call events
- Exchanges LiveKit room info via Matrix
- Manages ICE candidate signaling

**Key Methods:**
```dart
Future<void> sendInvite({
  required String roomId,
  required String callId,
  required String calleeId,
  required bool isVideoCall,
  required String liveKitRoom,
  required String liveKitToken,
})

Future<void> sendAnswer({...})
Future<void> sendHangup({...})
```

#### 3. CallRepositoryImpl (`lib/data/repositories/call_repository_impl.dart`)
- Coordinates LiveKit and Matrix signaling
- Manages call state (outgoing, incoming, active)
- Provides media controls
- Handles incoming/outgoing call streams

**Key Methods:**
```dart
Future<Either<Failure, CallEntity>> createCall({
  required String roomId,
  required String calleeId,
  required bool isVideoCall,
})

Future<Either<Failure, void>> answerCall({...})
Future<Either<Failure, void>> hangupCall({...})
Stream<CallEntity> get incomingCallStream
```

### Usage Flow

#### Making a Call:
1. User initiates call
2. Generate LiveKit room and token
3. Connect to LiveKit room
4. Enable local audio/video
5. Send Matrix `m.call.invite` event with LiveKit info
6. Wait for answer

#### Receiving a Call:
1. Listen for `m.call.invite` events
2. Parse LiveKit room info from event
3. Display incoming call UI
4. On answer, connect to LiveKit room
5. Enable local audio/video
6. Send Matrix `m.call.answer` event

#### Call Controls:
- Mute/unmute: `liveKitDataSource.setAudioEnabled(false/true)`
- Video on/off: `liveKitDataSource.setVideoEnabled(false/true)`
- Switch camera: `liveKitDataSource.switchCamera()`
- Hangup: `callRepository.hangupCall()`

---

## Building and Testing

### Prerequisites

1. Docker and docker-compose installed
2. Android device with USB debugging enabled (for testing)
3. ADB (Android Debug Bridge) available

### Build Commands

```bash
# Build debug APK
docker-compose -f docker/docker-compose.yml up android-builder

# Build release APK
docker-compose -f docker/docker-compose.yml up android-builder-release

# Using the build script
chmod +x docker/build-android.sh
./docker/build-android.sh --debug
./docker/build-android.sh --release
```

### Testing E2EE

1. Build and install APK on two Android devices
2. Log in with different accounts on each device
3. Create an encrypted room (or enable encryption in existing room)
4. Send messages - they should be encrypted end-to-end
5. Verify messages decrypt correctly on both devices

### Testing WebRTC Calls

1. Build and install APK
2. Log in on two devices
3. Navigate to a DM or room
4. Tap call button
5. Accept incoming call on other device
6. Verify audio/video works bidirectionally

---

## Known Limitations

### E2EE
- Key sharing protocol not fully implemented (room keys need server-side support)
- Device verification UI needs completion
- Cross-signing not yet implemented
- Key backup/restore needs server integration

### WebRTC
- LiveKit tokens currently generated client-side (needs server-side generation for production)
- LiveKit server URL hardcoded (needs configuration UI)
- Group calls need testing with 3+ participants
- Screen sharing not yet implemented

---

## Dependencies

### Flutter Packages
```yaml
olm: ^2.0.3  # E2EE cryptographic library
livekit_client: ^2.3.0  # WebRTC video/audio
flutter_secure_storage: ^9.0.0  # Secure key storage
```

### Platform Setup

**Android (AndroidManifest.xml):**
- Camera permission
- Microphone permission
- Internet permission
- Foreground service permission

**iOS (Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice calls</string>
```

---

## Troubleshooting

### E2EE Issues

**Problem**: Encryption fails with "Session not found"
**Solution**: Ensure both devices have exchanged keys. Check device verification status.

**Problem**: Cannot decrypt messages
**Solution**: Verify room key was properly shared. Check if inbound session exists.

### WebRTC Issues

**Problem**: Cannot connect to LiveKit room
**Solution**: Verify LiveKit server URL is correct. Check network connectivity.

**Problem**: No audio/video on call
**Solution**: Check camera/microphone permissions. Verify tracks are published.

---

## Next Steps

1. **Testing**: Complete end-to-end testing of both E2EE and WebRTC
2. **Documentation**: Update user-facing documentation
3. **Optimization**: Profile and optimize encryption performance
4. **Production**: Set up production LiveKit server and token generation
5. **Features**: Implement remaining features (screen sharing, group calls, etc.)

---

## File References

### E2EE Files
- `lib/data/datasources/olm_account_datasource.dart`
- `lib/data/datasources/olm_session_datasource.dart`
- `lib/data/datasources/megolm_session_datasource.dart`
- `lib/data/datasources/crypto_local_datasource.dart`
- `lib/data/repositories/crypto_repository_impl.dart`
- `lib/core/matrix/src/encryption/encryption_manager.dart`

### WebRTC Files
- `lib/data/datasources/livekit_datasource.dart`
- `lib/data/datasources/matrix_call_signaling_datasource.dart`
- `lib/data/repositories/call_repository_impl.dart`
- `lib/domain/entities/call.dart`

### Error Handling
- `lib/core/error/exceptions.dart` - New crypto exceptions added
- `lib/core/error/failures.dart` - New crypto failures added

---

## Security Notes

⚠️ **IMPORTANT**: This implementation is ready for testing but requires security review before production use.

- Ensure proper key rotation policies
- Review session management for vulnerabilities
- Test against known Matrix E2EE attack vectors
- Consider formal security audit

---

*For questions or issues, refer to the main project documentation or contact the development team.*
