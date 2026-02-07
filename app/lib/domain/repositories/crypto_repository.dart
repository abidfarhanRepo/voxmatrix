import 'package:dartz/dartz.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/entities/crypto.dart';

/// Repository for E2EE operations
abstract class CryptoRepository {
  /// Initialize E2EE - set up Olm account, upload device keys
  Future<Either<Failure, void>> initialize();

  /// Check if E2EE is enabled
  Future<Either<Failure, bool>> isEnabled();

  /// Get device keys for a user
  Future<Either<Failure, List<CryptoDevice>>> getUserDevices(String userId);

  /// Get all devices in a room
  Future<Either<Failure, List<CryptoDevice>>> getRoomDevices(String roomId);

  /// Verify a device
  Future<Either<Failure, void>> verifyDevice({
    required String userId,
    required String deviceId,
    bool verified = true,
  });

  /// Block a device
  Future<Either<Failure, void>> blockDevice({
    required String userId,
    required String deviceId,
    bool blocked = true,
  });

  /// Get crypto info for a room
  Future<Either<Failure, RoomCryptoInfo>> getRoomCryptoInfo(String roomId);

  /// Encrypt a message for a room
  Future<Either<Failure, String>> encryptMessage({
    required String roomId,
    required String plaintext,
  });

  /// Decrypt a message from a room
  Future<Either<Failure, String>> decryptMessage({
    required String roomId,
    required String ciphertext,
    required String senderKey,
    required String sessionId,
  });

  /// Get our own device info
  Future<Either<Failure, CryptoDevice>> getOwnDevice();

  /// Share room key with devices
  Future<Either<Failure, void>> shareRoomKey({
    required String roomId,
    required List<String> userIds,
  });

  /// Handle incoming key share request
  Future<Either<Failure, void>> handleKeyShareRequest(Map<String, dynamic> event);

  /// Reset E2EE - delete all keys and re-initialize
  Future<Either<Failure, void>> reset();

  /// Export keys for backup
  Future<Either<Failure, String>> exportKeys();

  /// Import keys from backup
  Future<Either<Failure, void>> importKeys(String keyData);

  /// Stream of device changes
  Stream<List<CryptoDevice>> get deviceChanges;

  /// Stream of verification requests
  Stream<VerificationRequest> get verificationRequests;
}

/// Verification request for device verification
class VerificationRequest {
  const VerificationRequest({
    required this.userId,
    required this.deviceId,
    this.timestamp,
  });

  final String userId;
  final String deviceId;
  final DateTime? timestamp;
}
