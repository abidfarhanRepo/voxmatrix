import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Megolm Session DataSource - Manages group encryption sessions
///
/// NOTE: E2EE is currently DISABLED due to olm native library crashes.
/// This stub implementation allows the app to start without crashing.
@injectable
class MegolmSessionDataSource {
  MegolmSessionDataSource(
    this._secureStorage,
    this._logger,
  );

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const String _outboundPrefix = 'megolm_outbound_';
  static const String _inboundPrefix = 'megolm_inbound_';

  /// Create outbound session for a room
  Future<Map<String, dynamic>> createOutboundSession(String roomId) async {
    _logger.w('E2EE disabled - createOutboundSession skipped');
    return {
      'session_id': 'disabled_${DateTime.now().millisecondsSinceEpoch}',
      'session_key': 'disabled',
      'message_index': 0,
    };
  }

  /// Get outbound session
  Future<dynamic> getOutboundSession(String roomId) async {
    return null;
  }

  /// Encrypt message
  Future<Map<String, dynamic>> encryptMessage({
    required String roomId,
    required String plaintext,
  }) async {
    _logger.w('E2EE disabled - encryptMessage skipped, returning plaintext');
    return {
      'ciphertext': plaintext,
      'session_id': 'disabled',
      'message_index': 0,
    };
  }

  /// Import inbound session
  Future<void> importInboundSession({
    required String roomId,
    required String sessionId,
    required String sessionKey,
    required String senderKey,
  }) async {
    _logger.w('E2EE disabled - importInboundSession skipped');
  }

  /// Decrypt message
  Future<Map<String, dynamic>> decryptMessage({
    required String roomId,
    required String sessionId,
    required String ciphertext,
  }) async {
    _logger.w('E2EE disabled - decryptMessage skipped');
    return {'plaintext': ciphertext, 'message_index': 0};
  }

  /// Get session key for sharing
  Future<Map<String, dynamic>?> getSessionKeyForSharing(String roomId) async {
    return null;
  }

  /// Check if has outbound session
  bool hasOutboundSession(String roomId) => false;

  /// Check if has inbound session
  Future<bool> hasInboundSession(String roomId, String sessionId) async {
    return false;
  }

  /// Clear room sessions
  Future<void> clearRoomSessions(String roomId) async {}

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    _logger.i('All Megolm sessions cleared (E2EE disabled)');
  }

  /// Dispose
  void dispose() {}
}
