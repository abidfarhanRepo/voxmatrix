/// Typing Manager for Matrix typing indicators
///
/// Handles sending and receiving typing notifications
/// See: https://spec.matrix.org/v1.11/client-server-api/#typing-notifications

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';

/// Typing Manager for typing indicators
class TypingManager {
  /// Create a new typing manager
  TypingManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Typing timeout timers for each room
  final Map<String, Timer> _typingTimers = {};

  /// Default typing timeout in milliseconds
  static const _defaultTypingTimeout = 30000; // 30 seconds

  /// Send a typing indicator
  ///
  /// [roomId] The room ID
  /// [isTyping] Whether the user is typing
  /// [timeout] Optional timeout in milliseconds (default: 30000)
  Future<void> sendTyping(
    String roomId,
    bool isTyping, {
    int timeout = _defaultTypingTimeout,
  }) async {
    if (isTyping) {
      _logger.d('Sending typing indicator for room $roomId');

      // Cancel existing timer if any
      _typingTimers[roomId]?.cancel();

      // Set up auto-cancel timer
      _typingTimers[roomId] = Timer(Duration(milliseconds: timeout), () {
        sendTyping(roomId, false);
      });
    } else {
      _logger.d('Clearing typing indicator for room $roomId');

      // Cancel the timer
      _typingTimers[roomId]?.cancel();
      _typingTimers.remove(roomId);
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/typing/${client.userId ?? ""}',
    );

    final body = jsonEncode({
      'typing': isTyping,
      'timeout': timeout,
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
      throw MatrixException('Failed to send typing indicator: ${response.statusCode}');
    }
  }

  /// Get currently typing users in a room
  ///
  /// This is typically handled via sync ephemeral events
  /// [roomId] The room ID
  /// [userIds] List of user IDs currently typing
  List<String> getTypingUsers(
    String roomId,
    List<String> userIds,
  ) {
    // Filter out the current user
    final currentUserId = client.userId;
    if (currentUserId != null) {
      return userIds.where((id) => id != currentUserId).toList();
    }
    return userIds;
  }

  /// Cancel typing for a room
  void cancelTyping(String roomId) {
    _typingTimers[roomId]?.cancel();
    _typingTimers.remove(roomId);
  }

  /// Dispose of the typing manager
  Future<void> dispose() async {
    // Cancel all timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    _logger.i('Typing manager disposed');
  }
}

/// Typing notification data
class TypingNotification {
  /// Create a typing notification from JSON
  factory TypingNotification.fromJson(Map<String, dynamic> json) {
    final userIds = json['user_ids'] as List? ?? [];
    return TypingNotification(
      userIds: userIds.cast<String>(),
    );
  }

  /// Create a new typing notification
  TypingNotification({
    this.userIds = const [],
  });

  /// The user IDs currently typing
  final List<String> userIds;

  /// Check if a specific user is typing
  bool isUserTyping(String userId) {
    return userIds.contains(userId);
  }

  /// Get the count of typing users
  int get count => userIds.length;
}
