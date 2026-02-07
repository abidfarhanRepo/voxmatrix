import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:voxmatrix/core/error/exceptions.dart';

/// Olm Account DataSource - Manages Olm cryptographic account
///
/// This datasource handles:
/// - Olm account creation and storage
/// - Identity key (Curve25519) management
/// - Signing key (Ed25519) management
/// - One-time key generation and management
/// - Account pickle/unpickle for persistence
///
/// NOTE: Olm native library is disabled due to SIGSEGV crashes on some devices.
/// E2EE features are temporarily disabled until the olm library compatibility
/// is fixed. This stub implementation allows the app to start without crashing.
@injectable
class OlmAccountDataSource {
  OlmAccountDataSource(
    this._secureStorage,
    this._logger,
  );

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  bool _isInitialized = false;
  bool _olmAvailable = false;

  // Secure storage keys
  static const String _accountPickleKey = 'olm_account_pickle';
  static const String _accountDataKey = 'olm_account_data';
  static const String _pickleKey = 'voxmatrix_olm_pickle_key';

  /// Check if Olm library is available
  bool get olmAvailable => _olmAvailable;

  /// Initialize Olm library
  Future<void> _initializeOlm() async {
    try {
      _logger.w('Olm library initialization skipped - E2EE disabled due to native crash issue');
      _olmAvailable = false;
      _isInitialized = true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Olm library', error: e, stackTrace: stackTrace);
      _olmAvailable = false;
      _isInitialized = true;
    }
  }

  /// Check if account exists and is initialized
  bool get hasAccount => false;

  /// Create a new Olm account
  Future<Map<String, dynamic>> createAccount() async {
    _logger.w('createAccount called but E2EE is disabled');
    return {
      'curve25519_key': 'disabled_$DateTime.now().millisecondsSinceEpoch',
      'ed25519_key': 'disabled_$DateTime.now().millisecondsSinceEpoch',
      'one_time_keys_count': 0,
      'olm_available': false,
    };
  }

  /// Load existing Olm account from secure storage
  Future<bool> loadAccount() async {
    _logger.w('loadAccount called but E2EE is disabled');
    return false;
  }

  /// Save Olm account to secure storage
  Future<void> _saveAccount() async {
    _logger.w('_saveAccount called but E2EE is disabled');
  }

  /// Get identity keys
  Map<String, String> getIdentityKeys() {
    _logger.w('getIdentityKeys called but E2EE is disabled');
    return {
      'curve25519': 'disabled_olm',
      'ed25519': 'disabled_olm',
    };
  }

  /// Get one-time keys for publishing to server
  Map<String, String> getOneTimeKeys() {
    _logger.w('getOneTimeKeys called but E2EE is disabled');
    return {};
  }

  /// Mark one-time keys as published
  void markOneTimeKeysAsPublished() {
    _logger.w('markOneTimeKeysAsPublished called but E2EE is disabled');
  }

  /// Generate more one-time keys
  void generateOneTimeKeys(int count) {
    _logger.w('generateOneTimeKeys called but E2EE is disabled');
  }

  /// Get count of unpublished one-time keys
  int _getOneTimeKeysCount() {
    return 0;
  }

  /// Get maximum number of one-time keys
  int get maxOneTimeKeys => 0;

  /// Sign a JSON object with Ed25519 key
  String signJson(Map<String, dynamic> json) {
    _logger.w('signJson called but E2EE is disabled');
    return '';
  }

  /// Canonicalize JSON for signing
  String _canonicalizeJson(Map<String, dynamic> json) {
    final sortedKeys = json.keys.toList()..sort();
    final sortedMap = <String, dynamic>{};
    for (final key in sortedKeys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        sortedMap[key] = _canonicalizeJson(value);
      } else {
        sortedMap[key] = value;
      }
    }
    return jsonEncode(sortedMap);
  }

  /// Get fallback key
  Map<String, dynamic>? getFallbackKey() {
    return null;
  }

  /// Forget old fallback key and generate new one
  void generateFallbackKey() {}

  /// Clear all stored data
  Future<void> clearAccount() async {
    await _secureStorage.delete(key: _accountPickleKey);
    await _secureStorage.delete(key: _accountDataKey);
    _logger.i('Olm account cleared (E2EE disabled)');
  }

  /// Dispose and cleanup
  void dispose() {
    _isInitialized = false;
    _logger.i('Olm account disposed (E2EE disabled)');
  }
}
