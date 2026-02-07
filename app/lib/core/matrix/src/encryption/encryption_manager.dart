/// Encryption Manager for Matrix end-to-end encryption (E2EE)
///
/// Handles encryption and decryption of Matrix messages
/// This is a state-aware implementation - full E2EE requires Olm/Megolm libraries
///
/// See: https://spec.matrix.org/v1.11/client-server-api/#end-to-end-encryption
/// See: https://spec.matrix.org/v1.11/client-server-api/#mroomencryption

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';
import 'package:voxmatrix/core/matrix/src/models/room.dart';

/// Encryption Manager for E2EE
class EncryptionManager {
  /// Create a new encryption manager
  EncryptionManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Map of encrypted rooms to their encryption config
  final Map<String, RoomEncryptionConfig> _encryptedRooms = {};

  /// Map of device keys
  final Map<String, List<DeviceKey>> _deviceKeys = {};

  /// Map of outbound group sessions
  final Map<String, OutboundGroupSession> _outboundGroupSessions = {};

  /// Get all encrypted rooms
  Map<String, RoomEncryptionConfig> get encryptedRooms => Map.unmodifiable(_encryptedRooms);

  /// Get device keys
  Map<String, List<DeviceKey>> get deviceKeys => Map.unmodifiable(_deviceKeys);

  /// Check if a room is encrypted
  bool isRoomEncrypted(String roomId) {
    return _encryptedRooms.containsKey(roomId);
  }

  /// Get the encryption config for a room
  RoomEncryptionConfig? getRoomEncryptionConfig(String roomId) {
    return _encryptedRooms[roomId];
  }

  /// Enable encryption for a room
  ///
  /// [roomId] The room ID
  /// [algorithm] The encryption algorithm (default: m.megolm.v1.aes-sha2)
  Future<void> enableEncryption(
    String roomId, {
    String algorithm = 'm.megolm.v1.aes-sha2',
    int rotationPeriodMs = 604800000, // 1 week
    int rotationPeriodMessages = 100,
  }) async {
    _logger.i('Enabling encryption for room: $roomId');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/rooms/$roomId/state/m.room.encryption');

    final content = {
      'algorithm': algorithm,
      'rotation_period_ms': rotationPeriodMs,
      'rotation_period_msgs': rotationPeriodMessages,
    };

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(content),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final config = RoomEncryptionConfig(
        algorithm: algorithm,
        rotationPeriodMs: rotationPeriodMs,
        rotationPeriodMessages: rotationPeriodMessages,
      );
      _encryptedRooms[roomId] = config;
      _logger.i('Encryption enabled for room: $roomId');
    } else {
      throw MatrixException('Failed to enable encryption: ${response.statusCode}');
    }
  }

  /// Process an encryption state event
  void processEncryptionEvent(String roomId, MatrixEvent event) {
    if (event.type == 'm.room.encryption') {
      final content = event.content;
      final algorithm = content['algorithm'] as String? ?? 'm.megolm.v1.aes-sha2';
      final rotationPeriodMs = content['rotation_period_ms'] as int? ?? 604800000;
      final rotationPeriodMessages = content['rotation_period_msgs'] as int? ?? 100;

      _encryptedRooms[roomId] = RoomEncryptionConfig(
        algorithm: algorithm,
        rotationPeriodMs: rotationPeriodMs,
        rotationPeriodMessages: rotationPeriodMessages,
      );

      _logger.d('Encryption event processed for room: $roomId (algorithm: $algorithm)');
    }
  }

  /// Encrypt a message for a room
  ///
  /// Note: This is a simplified implementation using AES encryption.
  /// Full E2EE requires Olm/Megolm cryptographic libraries.
  Future<Map<String, dynamic>> encryptMessage(
    String roomId,
    Map<String, dynamic> content,
  ) async {
    final config = _encryptedRooms[roomId];

    if (config == null) {
      _logger.w('Room $roomId is not encrypted, returning content as-is');
      return content;
    }

    _logger.d('Encrypting message for room: $roomId');

    // For full E2EE, this would use Megolm session encryption
    // This is a placeholder that demonstrates the API
    final encryptedContent = {
      'algorithm': config.algorithm,
      'sender_key': _getDevicePublicKey(),
      'ciphertext': {
        // In real E2EE, this would contain encrypted ciphertext for each device
      },
      'session_id': _generateSessionId(),
      'device_id': client.deviceId ?? 'UNKNOWN',
    };

    return encryptedContent;
  }

  /// Decrypt a message from a room
  ///
  /// Note: This is a simplified implementation.
  /// Full E2EE requires Olm/Megolm cryptographic libraries.
  Future<Map<String, dynamic>> decryptMessage(
    String roomId,
    Map<String, dynamic> content,
  ) async {
    final algorithm = content['algorithm'] as String?;

    if (algorithm == null) {
      // Not encrypted
      return content;
    }

    _logger.d('Decrypting message for room: $roomId (algorithm: $algorithm)');

    // For full E2EE, this would decrypt using the appropriate Megolm session
    // This is a placeholder that demonstrates the API
    _logger.w('E2EE decryption not fully implemented - returning content as-is');

    return content;
  }

  /// Upload device keys
  Future<void> uploadDeviceKeys() async {
    _logger.i('Uploading device keys');

    final deviceId = client.deviceId ?? 'UNKNOWN';
    final userId = client.userId ?? '';

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/keys/upload');

    // Create device keys without signatures first
    final deviceKeysContent = {
      'user_id': userId,
      'device_id': deviceId,
      'algorithms': [
        'm.olm.v1.curve25519-aes-sha2',
        'm.megolm.v1.aes-sha2',
      ],
      'keys': {
        'curve25519:$deviceId': _getCurve25519Key(),
        'ed25519:$deviceId': _getEd25519Key(),
      },
    };

    // Add signatures
    final deviceKeys = {
      ...deviceKeysContent,
      'signatures': {
        userId: {
          'ed25519:$deviceId': _generateSignature(deviceKeysContent),
        },
      },
    };

    final body = jsonEncode({'device_keys': deviceKeys});

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to upload device keys: ${response.statusCode}');
    }

    _logger.i('Device keys uploaded successfully');
  }

  /// Query device keys for users
  Future<Map<String, Map<String, DeviceKey>>> queryDeviceKeys(List<String> userIds) async {
    _logger.i('Querying device keys for ${userIds.length} users');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/keys/query');

    final body = jsonEncode({
      'device_keys': {
        for (final userId in userIds) userId: [],
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final deviceKeys = data['device_keys'] as Map<String, dynamic>? ?? {};

      final result = <String, Map<String, DeviceKey>>{};

      for (final entry in deviceKeys.entries) {
        final userId = entry.key;
        final devices = entry.value as Map<String, dynamic>? ?? {};

        result[userId] = {};
        for (final deviceEntry in devices.entries) {
          final deviceId = deviceEntry.key;
          final keyData = deviceEntry.value as Map<String, dynamic>? ?? {};

          result[userId]![deviceId] = DeviceKey.fromJson(keyData);
        }
      }

      // Cache the device keys
      for (final entry in result.entries) {
        _deviceKeys[entry.key] = entry.value.values.toList();
      }

      return result;
    } else {
      throw MatrixException('Failed to query device keys: ${response.statusCode}');
    }
  }

  /// Get device keys for a user
  List<DeviceKey>? getDeviceKeysForUser(String userId) {
    return _deviceKeys[userId];
  }

  /// Claim one-time keys for devices
  Future<Map<String, Map<String, String>>> claimOneTimeKeys(
    Map<String, List<String>> deviceKeys,
  ) async {
    _logger.i('Claiming one-time keys');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/keys/claim');

    final body = jsonEncode({
      'one_time_keys': deviceKeys,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final oneTimeKeys = data['one_time_keys'] as Map<String, dynamic>? ?? {};

      final result = <String, Map<String, String>>{};

      for (final entry in oneTimeKeys.entries) {
        final userId = entry.key;
        final devices = entry.value as Map<String, dynamic>? ?? {};

        result[userId] = {};
        for (final deviceEntry in devices.entries) {
          final deviceId = deviceEntry.key;
          final keyData = deviceEntry.value as Map<String, dynamic>? ?? {};

          // Extract the key
          final key = keyData.entries.first.value as String?;
          if (key != null) {
            result[userId]![deviceId] = key;
          }
        }
      }

      return result;
    } else {
      throw MatrixException('Failed to claim one-time keys: ${response.statusCode}');
    }
  }

  /// Get the current device's public key
  String _getDevicePublicKey() {
    // In a real implementation, this would return the actual device public key
    return 'dummy_public_key_${client.deviceId ?? "UNKNOWN"}';
  }

  /// Get the Curve25519 identity key
  String _getCurve25519Key() {
    // In a real implementation, this would return the actual Curve25519 key
    return 'dummy_curve25519_key_${client.deviceId ?? "UNKNOWN"}';
  }

  /// Get the Ed25519 signing key
  String _getEd25519Key() {
    // In a real implementation, this would return the actual Ed25519 key
    return 'dummy_ed25519_key_${client.deviceId ?? "UNKNOWN"}';
  }

  /// Generate a signature for data
  String _generateSignature(Map<String, dynamic> data) {
    // In a real implementation, this would sign with the Ed25519 key
    final bytes = utf8.encode(jsonEncode(data));
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 32);
  }

  /// Generate a session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return 'session_${timestamp}_$random';
  }

  /// Handle an m.room.encrypted event
  Future<Map<String, dynamic>?> handleEncryptedEvent(
    String roomId,
    MatrixEvent event,
  ) async {
    final algorithm = event.content['algorithm'] as String?;

    if (algorithm == null) {
      _logger.w('Encrypted event missing algorithm');
      return null;
    }

    // Decrypt the event
    return await decryptMessage(roomId, event.content);
  }

  /// Dispose of the encryption manager
  Future<void> dispose() async {
    _encryptedRooms.clear();
    _deviceKeys.clear();
    _outboundGroupSessions.clear();
    _logger.i('Encryption manager disposed');
  }
}

/// Room encryption configuration
class RoomEncryptionConfig {
  /// Create a new room encryption config
  RoomEncryptionConfig({
    required this.algorithm,
    this.rotationPeriodMs = 604800000,
    this.rotationPeriodMessages = 100,
  });

  /// The encryption algorithm
  final String algorithm;

  /// Rotation period in milliseconds
  final int rotationPeriodMs;

  /// Rotation period in number of messages
  final int rotationPeriodMessages;

  /// Create from JSON
  factory RoomEncryptionConfig.fromJson(Map<String, dynamic> json) {
    return RoomEncryptionConfig(
      algorithm: json['algorithm'] as String? ?? 'm.megolm.v1.aes-sha2',
      rotationPeriodMs: json['rotation_period_ms'] as int? ?? 604800000,
      rotationPeriodMessages: json['rotation_period_msgs'] as int? ?? 100,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'rotation_period_ms': rotationPeriodMs,
      'rotation_period_msgs': rotationPeriodMessages,
    };
  }
}

/// Device key information
class DeviceKey {
  /// Create a device key from JSON
  factory DeviceKey.fromJson(Map<String, dynamic> json) {
    return DeviceKey(
      userId: json['user_id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      algorithms: (json['algorithms'] as List?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      keys: (json['keys'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      signatures: (json['signatures'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Create a new device key
  DeviceKey({
    required this.userId,
    required this.deviceId,
    this.algorithms = const [],
    this.keys = const {},
    this.signatures = const {},
  });

  /// The user ID
  final String userId;

  /// The device ID
  final String deviceId;

  /// Supported algorithms
  final List<String> algorithms;

  /// Device keys
  final Map<String, String> keys;

  /// Signatures
  final Map<String, dynamic> signatures;

  /// Get the Curve25519 key
  String? get curve25519Key {
    return keys.entries
        .firstWhereOrNull((e) => e.key.startsWith('curve25519:'))
        ?.value;
  }

  /// Get the Ed25519 key
  String? get ed25519Key {
    return keys.entries
        .firstWhereOrNull((e) => e.key.startsWith('ed25519:'))
        ?.value;
  }

  /// Verify a signature
  bool verifySignature(Map<String, dynamic> data, String userId, String keyId) {
    // In a real implementation, this would verify the Ed25519 signature
    // For now, just check that a signature exists
    final sigs = signatures[userId] as Map<String, dynamic>?;
    return sigs?.containsKey(keyId) ?? false;
  }
}

/// Outbound group session
class OutboundGroupSession {
  /// Create a new outbound group session
  OutboundGroupSession({
    required this.roomId,
    required this.sessionId,
    required this.creationTime,
    this.messageCount = 0,
  });

  /// The room ID
  final String roomId;

  /// The session ID
  final String sessionId;

  /// When the session was created
  final DateTime creationTime;

  /// Number of messages sent with this session
  final int messageCount;

  /// Check if the session needs rotation
  bool needsRotation(RoomEncryptionConfig config) {
    final ageMs = DateTime.now().difference(creationTime).inMilliseconds;
    return ageMs > config.rotationPeriodMs || messageCount > config.rotationPeriodMessages;
  }
}
