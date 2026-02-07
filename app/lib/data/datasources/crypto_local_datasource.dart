import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/megolm_session_datasource.dart';
import 'package:voxmatrix/data/datasources/olm_account_datasource.dart';
import 'package:voxmatrix/data/datasources/olm_session_datasource.dart';
import 'package:voxmatrix/domain/entities/crypto.dart';

/// Enhanced Local datasource for E2EE key storage and management
///
/// NOTE: E2EE is currently DISABLED due to olm native library SIGSEGV crashes.
/// This stub implementation allows the app to start and run without crashes.
/// All E2EE operations return stub/fallback data.
@injectable
class CryptoLocalDataSource {
  CryptoLocalDataSource(
    this._secureStorage,
    this._olmAccountDataSource,
    this._olmSessionDataSource,
    this._megolmSessionDataSource,
    this._authLocalDataSource,
    this._logger,
  );

  final FlutterSecureStorage _secureStorage;
  final OlmAccountDataSource _olmAccountDataSource;
  final OlmSessionDataSource _olmSessionDataSource;
  final MegolmSessionDataSource _megolmSessionDataSource;
  final AuthLocalDataSource _authLocalDataSource;
  final Logger _logger;

  static const String _deviceIdKey = 'crypto_device_id';
  static const String _trustedDevicesPrefix = 'crypto_trusted_device_';
  bool _e2eeEnabled = false;

  /// Initialize Olm account for the user
  Future<Either<Failure, Map<String, dynamic>>> initializeAccount({
    required String userId,
  }) async {
    try {
      _logger.i('Initializing crypto account for user: $userId');
      _logger.w('E2EE is DISABLED due to native library crash issues');
      _e2eeEnabled = false;

      final deviceId = await _getOrCreateDeviceId();
      return Right({
        'user_id': userId,
        'device_id': deviceId,
        'curve25519_key': 'disabled',
        'ed25519_key': 'disabled',
        'one_time_keys_count': 0,
        'is_new': false,
        'e2ee_enabled': false,
      });
    } catch (e, stackTrace) {
      _logger.e('Error initializing account', error: e, stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to initialize crypto account: $e'));
    }
  }

  /// Get or create device ID
  Future<String> _getOrCreateDeviceId() async {
    var deviceId = await _secureStorage.read(key: _deviceIdKey);
    
    if (deviceId == null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = timestamp % 10000;
      deviceId = 'VMX${timestamp}_$random';
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      _logger.i('Generated new device ID: $deviceId');
    }
    
    return deviceId;
  }

  /// Get current device ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey);
  }

  /// Get stored device keys
  Future<Either<Failure, CryptoDevice>> getOwnDevice() async {
    try {
      final deviceId = await getDeviceId();
      final userId = await _authLocalDataSource.getUserId();

      if (deviceId == null || userId == null) {
        return const Left(CacheFailure(message: 'Crypto account not initialized'));
      }

      return Right(CryptoDevice(
        deviceId: deviceId,
        userId: userId,
        publicKey: 'disabled',
        displayName: 'This Device',
        verificationStatus: DeviceVerificationStatus.verified,
        lastSeen: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      _logger.e('Error getting own device', error: e, stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to get device info: $e'));
    }
  }

  /// Get identity keys for upload to server
  Future<Either<Failure, Map<String, dynamic>>> getIdentityKeysForUpload() async {
    return Right({
      'identity_keys': {'curve25519': 'disabled', 'ed25519': 'disabled'},
      'one_time_keys': {},
    });
  }

  /// Mark one-time keys as published
  Future<void> markOneTimeKeysAsPublished() async {}

  /// Generate more one-time keys
  Future<void> generateOneTimeKeys(int count) async {}

  /// Create an outbound Olm session for a device
  Future<Either<Failure, void>> createOlmSession({
    required String theirDeviceId,
    required String theirIdentityKey,
    required String theirOneTimeKey,
  }) async {
    _logger.w('E2EE disabled - createOlmSession skipped');
    return const Right(null);
  }

  /// Encrypt a message for a specific device using Olm
  Future<Either<Failure, Map<String, dynamic>>> encryptOlmMessage({
    required String theirDeviceId,
    required String plaintext,
  }) async {
    _logger.w('E2EE disabled - encryptOlmMessage skipped, returning plaintext');
    return Right({'type': 0, 'body': plaintext});
  }

  /// Decrypt a message from a device using Olm
  Future<Either<Failure, String>> decryptOlmMessage({
    required String theirDeviceId,
    required int messageType,
    required String ciphertext,
  }) async {
    _logger.w('E2EE disabled - decryptOlmMessage skipped');
    return Right(ciphertext);
  }

  /// Create or get Megolm outbound session for a room
  Future<Either<Failure, Map<String, dynamic>>> createMegolmSession(String roomId) async {
    _logger.w('E2EE disabled - createMegolmSession skipped');
    return Right({'session_id': 'disabled', 'session_key': 'disabled'});
  }

  /// Encrypt a message for a room using Megolm
  Future<Either<Failure, Map<String, dynamic>>> encryptMegolmMessage({
    required String roomId,
    required String plaintext,
  }) async {
    _logger.w('E2EE disabled - encryptMegolmMessage skipped, returning plaintext');
    return Right({'type': 0, 'body': plaintext});
  }

  /// Import an inbound Megolm session
  Future<Either<Failure, void>> importMegolmSession({
    required String roomId,
    required String sessionId,
    required String sessionKey,
    required String senderKey,
  }) async {
    return const Right(null);
  }

  /// Decrypt a Megolm-encrypted message
  Future<Either<Failure, String>> decryptMegolmMessage({
    required String roomId,
    required String sessionId,
    required String ciphertext,
  }) async {
    return Right(ciphertext);
  }

  /// Store trusted device
  Future<Either<Failure, void>> setDeviceTrusted({
    required String userId,
    required String deviceId,
    required bool trusted,
  }) async {
    try {
      final key = '$_trustedDevicesPrefix${userId}_$deviceId';
      if (trusted) {
        await _secureStorage.write(
          key: key,
          value: jsonEncode({'trusted': true, 'timestamp': DateTime.now().toIso8601String()}),
        );
      } else {
        await _secureStorage.delete(key: key);
      }
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error setting device trust', error: e, stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to update device trust: $e'));
    }
  }

  /// Check if device is trusted
  Future<bool> isDeviceTrusted({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final key = '$_trustedDevicesPrefix${userId}_$deviceId';
      final data = await _secureStorage.read(key: key);
      if (data == null) return false;
      final json = jsonDecode(data) as Map<String, dynamic>;
      return json['trusted'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Sign data with Ed25519 key
  Future<Either<Failure, String>> signData(Map<String, dynamic> data) async {
    return Right('disabled_signature');
  }

  /// Export all keys
  Future<Either<Failure, String>> exportKeys() async {
    final deviceId = await getDeviceId();
    final exportData = {
      'device_id': deviceId,
      'account_keys': {'curve25519': 'disabled', 'ed25519': 'disabled'},
      'exported_at': DateTime.now().toIso8601String(),
      'version': 1,
      'e2ee_enabled': false,
    };
    return Right(jsonEncode(exportData));
  }

  /// Import keys
  Future<Either<Failure, void>> importKeys(String keyData) async {
    try {
      final data = jsonDecode(keyData) as Map<String, dynamic>;
      final deviceId = data['device_id'] as String?;
      if (deviceId != null) {
        await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      }
      _logger.i('Keys imported (E2EE remains disabled)');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error importing keys', error: e, stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to import keys: $e'));
    }
  }

  /// Reset - delete all crypto data
  Future<Either<Failure, void>> reset() async {
    try {
      await _olmAccountDataSource.clearAccount();
      await _olmSessionDataSource.clearAllSessions();
      await _megolmSessionDataSource.clearAllSessions();
      await _secureStorage.delete(key: _deviceIdKey);
      final allKeys = await _secureStorage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_trustedDevicesPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }
      _logger.i('Crypto data reset');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error resetting crypto', error: e, stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to reset crypto: $e'));
    }
  }

  /// Dispose and cleanup
  void dispose() {
    _olmAccountDataSource.dispose();
    _olmSessionDataSource.dispose();
    _megolmSessionDataSource.dispose();
  }
}
