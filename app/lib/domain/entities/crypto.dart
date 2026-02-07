import 'package:equatable/equatable.dart';

/// Encryption algorithm types supported by Matrix
enum EncryptionAlgorithm {
  /// Megolm v1 (recommended for rooms)
  megolmV1('m.megolm.v1.aes-sha2'),

  /// Olm v1 (for 1:1 sessions)
  olmV1('m.olm.v1.curve25519-aes-sha2'),

  /// No encryption
  none('m.room.noencryption');

  const EncryptionAlgorithm(this.value);
  final String value;

  static EncryptionAlgorithm fromValue(String value) {
    return EncryptionAlgorithm.values.firstWhere(
      (alg) => alg.value == value,
      orElse: () => EncryptionAlgorithm.none,
    );
  }
}

/// Encryption state of a room
enum RoomEncryptionState {
  /// Room is encrypted and trusted
  encrypted,

  /// Room is encrypted but has unverified devices
  encryptedUnverified,

  /// Room is not encrypted
  unencrypted,

  /// Encryption state unknown
  unknown,
}

/// Device verification status
enum DeviceVerificationStatus {
  /// Device is verified and trusted
  verified,

  /// Device is unverified
  unverified,

  /// Device is blocked
  blocked,

  /// Unknown status
  unknown,
}

/// Represents a Matrix device for E2EE
class CryptoDevice extends Equatable {
  const CryptoDevice({
    required this.deviceId,
    required this.userId,
    required this.publicKey,
    this.displayName,
    this.verificationStatus = DeviceVerificationStatus.unknown,
    this.lastSeen,
  });

  final String deviceId;
  final String userId;
  final String publicKey;
  final String? displayName;
  final DeviceVerificationStatus verificationStatus;
  final DateTime? lastSeen;

  CryptoDevice copyWith({
    String? deviceId,
    String? userId,
    String? publicKey,
    String? displayName,
    DeviceVerificationStatus? verificationStatus,
    DateTime? lastSeen,
  }) {
    return CryptoDevice(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      publicKey: publicKey ?? this.publicKey,
      displayName: displayName ?? this.displayName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    userId,
    publicKey,
    displayName,
    verificationStatus,
    lastSeen,
  ];

  bool get isVerified => verificationStatus == DeviceVerificationStatus.verified;
  bool get isBlocked => verificationStatus == DeviceVerificationStatus.blocked;
  bool get isUnverified => verificationStatus == DeviceVerificationStatus.unverified;
}

/// Represents a Megolm session for encrypted room messages
class MegolmSession extends Equatable {
  const MegolmSession({
    required this.roomId,
    required this.sessionId,
    required this.senderKey,
    this.algorithm = EncryptionAlgorithm.megolmV1,
    this.createdAt,
  });

  final String roomId;
  final String sessionId;
  final String senderKey;
  final EncryptionAlgorithm algorithm;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [roomId, sessionId, senderKey, algorithm, createdAt];
}

/// Crypto information for a room
class RoomCryptoInfo extends Equatable {
  const RoomCryptoInfo({
    required this.roomId,
    required this.encryptionState,
    this.algorithm,
    this.shouldEncrypt = false,
    this.blacklistedUnverifiedDevices = false,
    this.devices,
  });

  final String roomId;
  final RoomEncryptionState encryptionState;
  final EncryptionAlgorithm? algorithm;
  final bool shouldEncrypt;
  final bool blacklistedUnverifiedDevices;
  final List<CryptoDevice>? devices;

  RoomCryptoInfo copyWith({
    String? roomId,
    RoomEncryptionState? encryptionState,
    EncryptionAlgorithm? algorithm,
    bool? shouldEncrypt,
    bool? blacklistedUnverifiedDevices,
    List<CryptoDevice>? devices,
  }) {
    return RoomCryptoInfo(
      roomId: roomId ?? this.roomId,
      encryptionState: encryptionState ?? this.encryptionState,
      algorithm: algorithm ?? this.algorithm,
      shouldEncrypt: shouldEncrypt ?? this.shouldEncrypt,
      blacklistedUnverifiedDevices:
          blacklistedUnverifiedDevices ?? this.blacklistedUnverifiedDevices,
      devices: devices ?? this.devices,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    encryptionState,
    algorithm,
    shouldEncrypt,
    blacklistedUnverifiedDevices,
    devices,
  ];

  bool get isEncrypted => encryptionState == RoomEncryptionState.encrypted ||
      encryptionState == RoomEncryptionState.encryptedUnverified;

  bool get hasUnverifiedDevices =>
      encryptionState == RoomEncryptionState.encryptedUnverified;
}
