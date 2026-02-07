/// To-Device Manager for MatrixToDevice messaging
///
/// Handles sending events directly to devices without going through rooms
/// See: https://spec.matrix.org/v1.11/client-server-api/#send-to-device-events

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';

/// To-Device Manager
class ToDeviceManager {
  /// Create a new to-device manager
  ToDeviceManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Send aToDevice event
  ///
  /// [eventType] The event type (e.g., 'm.room_key_request', 'm.verification')
  /// [content] The event content
  /// [userId] The target user ID
  /// [deviceId] The target device ID (or '*' for all devices)
  Future<void> sendToDevice(
    String eventType,
    Map<String, dynamic> content,
    String userId,
    String deviceId,
  ) async {
    _logger.i('Sending to-device event $eventType to $userId:$deviceId');

    final txnId = client.generateTxnId();
    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/sendToDevice/$eventType/$txnId',
    );

    final body = jsonEncode({
      userId: {
        deviceId: content,
      },
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
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to send to-device event: $error');
    }

    _logger.i('To-device event sent successfully');
  }

  /// Send aToDevice event to multiple devices
  ///
  /// [eventType] The event type
  /// [messages] Map of userId -> deviceId -> content
  Future<void> sendToDeviceMultiple(
    String eventType,
    Map<String, Map<String, Map<String, dynamic>>> messages,
  ) async {
    _logger.i('Sending to-device event $eventType to ${messages.length} users');

    final txnId = client.generateTxnId();
    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/sendToDevice/$eventType/$txnId',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(messages),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to send to-device event: $error');
    }

    _logger.i('To-device event sent successfully to multiple devices');
  }

  /// Dispose of the to-device manager
  Future<void> dispose() async {
    _logger.i('To-device manager disposed');
  }
}
