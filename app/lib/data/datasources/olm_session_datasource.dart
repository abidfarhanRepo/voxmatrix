import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Olm Session DataSource - Manages Olm encryption sessions for 1:1 E2EE
///
/// NOTE: E2EE is currently DISABLED due to olm native library crashes.
/// This stub implementation allows the app to start without crashing.
@injectable
class OlmSessionDataSource {
  OlmSessionDataSource(
    this._secureStorage,
    this._logger,
  );

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const String _sessionsKey = 'olm_sessions';

  /// Create outbound Olm session
  Future<void> createOutboundSession({
    required String theirDeviceId,
    required String theirIdentityKey,
    required String theirOneTimeKey,
  }) async {
    _logger.w('E2EE disabled - createOutboundSession skipped');
  }

  /// Create inbound Olm session from pre-key message
  Future<void> createInboundSession({
    required String theirDeviceId,
    required String theirIdentityKey,
    required String preKeyMessage,
  }) async {
    _logger.w('E2EE disabled - createInboundSession skipped');
  }

  /// Get session for device
  Future<dynamic?> getSession({
    required String theirDeviceId,
    required bool outbound,
  }) async {
    _logger.w('E2EE disabled - getSession returned null');
    return null;
  }

  /// Encrypt message
  Future<Map<String, dynamic>> encryptMessage({
    required dynamic session,
    required String plaintext,
  }) async {
    return {'type': 0, 'body': plaintext};
  }

  /// Decrypt message
  Future<String> decryptMessage({
    required dynamic session,
    required int messageType,
    required String ciphertext,
  }) async {
    return ciphertext;
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    await _secureStorage.delete(key: _sessionsKey);
  }

  /// Dispose
  void dispose() {}
}
