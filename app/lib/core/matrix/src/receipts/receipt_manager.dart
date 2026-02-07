/// Receipt Manager for Matrix read receipts
///
/// Handles sending and receiving read receipts (m.read)
/// See: https://spec.matrix.org/v1.11/client-server-api/#sending-read-receipts

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';

/// Receipt Manager for read receipts
class ReceiptManager {
  /// Create a new receipt manager
  ReceiptManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Send a read receipt for an event
  ///
  /// [roomId] The room ID
  /// [eventId] The event ID to mark as read
  Future<void> sendReadReceipt(
    String roomId,
    String eventId,
  ) async {
    _logger.d('Sending read receipt for event $eventId in room $roomId');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/receipt/m.read/$eventId',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: '{}',
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to send read receipt: ${response.statusCode}');
    }

    _logger.d('Read receipt sent successfully');
  }

  /// Send a fully read receipt for an event
  ///
  /// This marks the event as fully read, which is used for notifications
  /// [roomId] The room ID
  /// [eventId] The event ID to mark as fully read
  Future<void> sendFullyReadReceipt(
    String roomId,
    String eventId,
  ) async {
    _logger.d('Sending fully read receipt for event $eventId in room $roomId');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/receipt/m.fully_read/$eventId',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: '{}',
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to send fully read receipt: ${response.statusCode}');
    }

    _logger.d('Fully read receipt sent successfully');
  }

  /// Get read receipts for an event
  ///
  /// [roomId] The room ID
  /// [eventId] The event ID
  Future<List<ReadReceipt>> getReadReceipts(
    String roomId,
    String eventId,
  ) async {
    _logger.d('Getting read receipts for event $eventId in room $roomId');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/read_receipts/$eventId',
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
      final receipts = data['read_receipts'] as List? ?? [];
      return receipts
          .map((r) => r is Map<String, dynamic> ? ReadReceipt.fromJson(r) : null)
          .whereType<ReadReceipt>()
          .toList();
    } else {
      throw MatrixException('Failed to get read receipts: ${response.statusCode}');
    }
  }

  /// Dispose of the receipt manager
  Future<void> dispose() async {
    _logger.i('Receipt manager disposed');
  }
}

/// Read receipt information
class ReadReceipt {
  /// Create a read receipt from JSON
  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      userId: json['user_id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      timestamp: json['ts'] as int? ?? 0,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Create a new read receipt
  ReadReceipt({
    required this.userId,
    required this.eventId,
    required this.timestamp,
    this.data = const {},
  });

  /// The user who sent the receipt
  final String userId;

  /// The event ID that was read
  final String eventId;

  /// The timestamp of the receipt
  final int timestamp;

  /// Additional data
  final Map<String, dynamic> data;
}
