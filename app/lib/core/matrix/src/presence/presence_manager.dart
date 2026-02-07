/// Presence Manager for Matrix user presence
///
/// Handles setting and retrieving user presence status
/// See: https://spec.matrix.org/v1.11/client-server-api/#presence

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';

/// Presence status
enum PresenceStatus {
  /// User is online
  online('online'),

  /// User is unavailable
  unavailable('unavailable'),

  /// User is offline
  offline('offline');

  final String value;
  const PresenceStatus(this.value);

  static PresenceStatus fromString(String value) {
    return PresenceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PresenceStatus.offline,
    );
  }
}

/// Presence Manager
class PresenceManager {
  /// Create a new presence manager
  PresenceManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Set own presence status
  ///
  /// [status] The presence status (online, unavailable, offline)
  /// [statusMessage] Optional status message
  Future<void> setPresence(
    PresenceStatus status, {
    String? statusMessage,
  }) async {
    _logger.i('Setting presence to: ${status.value}');

    final userId = client.userId;
    if (userId == null) {
      throw MatrixException('Cannot set presence: user ID not set');
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/presence/$userId/status',
    );

    final body = jsonEncode({
      'presence': status.value,
      if (statusMessage != null) 'status_msg': statusMessage,
    });

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set presence: ${response.statusCode}');
    }

    _logger.i('Presence set successfully');
  }

  /// Get presence status for a user
  ///
  /// [userId] The user ID to get presence for
  Future<PresenceInfo> getPresence(String userId) async {
    _logger.d('Getting presence for user: $userId');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/presence/$userId/status',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PresenceInfo.fromJson(data);
    } else {
      throw MatrixException('Failed to get presence: ${response.statusCode}');
    }
  }

  /// Get presence status for multiple users
  ///
  /// [userIds] List of user IDs to get presence for
  Future<Map<String, PresenceInfo>> getPresenceList(List<String> userIds) async {
    _logger.d('Getting presence for ${userIds.length} users');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/presence/list',
    );

    final body = jsonEncode({
      'users': userIds,
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
      final result = <String, PresenceInfo>{};

      for (final entry in data.entries) {
        result[entry.key] = PresenceInfo.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      return result;
    } else {
      throw MatrixException('Failed to get presence list: ${response.statusCode}');
    }
  }

  /// Subscribe to presence updates for users
  ///
  /// [userIds] List of user IDs to subscribe to
  Future<void> subscribeToPresence(List<String> userIds) async {
    _logger.i('Subscribing to presence for ${userIds.length} users');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/presence/list',
    );

    final body = jsonEncode({
      'users': userIds,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to subscribe to presence: ${response.statusCode}');
    }

    _logger.i('Presence subscription successful');
  }

  /// Dispose of the presence manager
  Future<void> dispose() async {
    _logger.i('Presence manager disposed');
  }
}

/// Presence information
class PresenceInfo {
  /// Create presence info from JSON
  factory PresenceInfo.fromJson(Map<String, dynamic> json) {
    return PresenceInfo(
      userId: json['user_id'] as String? ?? '',
      presence: PresenceStatus.fromString(
        json['presence'] as String? ?? 'offline',
      ),
      lastActiveAgo: json['last_active_ago'] as int?,
      statusMessage: json['status_msg'] as String?,
      currentlyActive: json['currently_active'] as bool? ?? false,
    );
  }

  /// Create new presence info
  PresenceInfo({
    required this.userId,
    required this.presence,
    this.lastActiveAgo,
    this.statusMessage,
    this.currentlyActive = false,
  });

  /// The user ID
  final String userId;

  /// The presence status
  final PresenceStatus presence;

  /// milliseconds since last active
  final int? lastActiveAgo;

  /// Optional status message
  final String? statusMessage;

  /// Whether the user is currently active
  final bool currentlyActive;

  /// Get the last active time as a DateTime
  DateTime? get lastActiveTime {
    if (lastActiveAgo != null) {
      return DateTime.now().subtract(Duration(milliseconds: lastActiveAgo!));
    }
    return null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'presence': presence.value,
      if (lastActiveAgo != null) 'last_active_ago': lastActiveAgo,
      if (statusMessage != null) 'status_msg': statusMessage,
      'currently_active': currentlyActive,
    };
  }
}
