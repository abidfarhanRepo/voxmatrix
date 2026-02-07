/// Message Operations Manager for Matrix message actions
///
/// Handles message editing, reactions, redaction, and replies
/// See: https://spec.matrix.org/v1.11/client-server-api/#message-relaying

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';

/// Message Operations Manager
class MessageOperationsManager {
  /// Create a new message operations manager
  MessageOperationsManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Edit a message
  ///
  /// [roomId] The room ID
  /// [eventId] The event ID of the message to edit
  /// [newContent] The new message content
  /// [originalContent] Optional original content for the edit
  Future<String> editMessage(
    String roomId,
    String eventId,
    Map<String, dynamic> newContent, {
    Map<String, dynamic>? originalContent,
  }) async {
    _logger.i('Editing message $eventId in room $roomId');

    final newEventId = await sendEvent(
      roomId,
      'm.room.message',
      {
        'm.new_content': newContent,
        'm.relates_to': {
          'rel_type': 'm.replace',
          'event_id': eventId,
        },
        ...newContent,
      },
    );

    _logger.i('Message edited successfully: $newEventId');
    return newEventId;
  }

  /// React to a message
  ///
  /// [roomId] The room ID
  /// [eventId] The event ID to react to
  /// [emoji] The emoji reaction (e.g., '👍', '❤️')
  Future<String> reactToMessage(
    String roomId,
    String eventId,
    String emoji,
  ) async {
    _logger.i('Adding reaction $emoji to event $eventId in room $roomId');

    final relation = {
      'rel_type': 'm.annotation',
      'event_id': eventId,
      'key': emoji,
    };

    final event = await sendEvent(
      roomId,
      'm.reaction',
      {
        'm.relates_to': relation,
      },
    );

    _logger.i('Reaction added successfully: $event');
    return event;
  }

  /// Redact (delete) a message
  ///
  /// [roomId] The room ID
  /// [eventId] The event ID to redact
  /// [reason] Optional reason for redaction
  Future<String> redactEvent(
    String roomId,
    String eventId, {
    String? reason,
  }) async {
    _logger.i('Redacting event $eventId in room $roomId');

    final txnId = client.generateTxnId();
    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/redact/$eventId/$txnId',
    );

    final body = reason != null
        ? jsonEncode({'reason': reason})
        : jsonEncode({});

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to redact event: $error');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newEventId = data['event_id'] as String?;

    _logger.i('Event redacted successfully: ${newEventId ?? eventId}');
    return newEventId ?? eventId;
  }

  /// Reply to a message
  ///
  /// [roomId] The room ID
  /// [eventId] The event ID being replied to
  /// [content] The reply message content
  /// [replyText] Optional formatted reply text
  Future<String> replyToMessage(
    String roomId,
    String eventId,
    Map<String, dynamic> content, {
    String? replyText,
  }) async {
    _logger.i('Replying to event $eventId in room $roomId');

    final replyContent = {
      'msgtype': content['msgtype'] ?? 'm.text',
      'body': replyText ?? (content['body'] as String? ?? ''),
      'm.relates_to': {
        'rel_type': 'm.reference',
        'event_id': eventId,
      },
    };

    final event = await sendEvent(
      roomId,
      'm.room.message',
      replyContent,
    );

    _logger.i('Reply sent successfully: $event');
    return event;
  }

  /// Send a message with reply fallback
  ///
  /// This creates a proper reply with the original message quoted
  /// [roomId] The room ID
  /// [eventId] The event ID being replied to
  /// [originalEvent] The original event being replied to
  /// [text] The reply text
  Future<String> sendReplyWithFallback(
    String roomId,
    String eventId,
    MatrixEvent originalEvent,
    String text,
  ) async {
    _logger.i('Sending reply with fallback to event $eventId in room $roomId');

    final originalSender = originalEvent.senderId ?? '';
    final originalBody = originalEvent.messageBody ?? '';
    final senderDisplay = originalSender.split(':')[0].replaceAll('@', '');

    // Create the fallback body for clients that don't support replies
    final fallbackBody = '> <$senderDisplay> $originalBody\n$text';

    final formattedBody = '> <$senderDisplay> $originalBody\n$text';

    final replyContent = {
      'msgtype': 'm.text',
      'body': fallbackBody,
      'formatted_body': formattedBody,
      'format': 'org.matrix.custom.html',
      'm.relates_to': {
        'rel_type': 'm.reference',
        'event_id': eventId,
      },
    };

    final event = await sendEvent(
      roomId,
      'm.room.message',
      replyContent,
    );

    _logger.i('Reply with fallback sent successfully: $event');
    return event;
  }

  /// Get related events for an event
  ///
  /// This gets reactions, edits, and replies for a given event
  /// [roomId] The room ID
  /// [eventId] The event ID
  /// [relationType] Optional relation type filter (e.g., 'm.annotation', 'm.replace')
  Future<List<MatrixEvent>> getRelatedEvents(
    String roomId,
    String eventId, {
    String? relationType,
    int limit = 10,
  }) async {
    _logger.d('Getting related events for $eventId in room $roomId');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/rooms/$roomId/relations/$eventId');

    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (relationType != null) {
      queryParams['rel_type'] = relationType;
    }

    final response = await http.get(
      url.replace(queryParameters: queryParams),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final chunk = data['chunk'] as List? ?? [];

      return chunk
          .map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
          .whereType<MatrixEvent>()
          .toList();
    } else {
      throw MatrixException('Failed to get related events: ${response.statusCode}');
    }
  }

  /// Get reactions for an event
  Future<List<MatrixEvent>> getReactions(
    String roomId,
    String eventId,
  ) async {
    return await getRelatedEvents(
      roomId,
      eventId,
      relationType: 'm.annotation',
      limit: 100,
    );
  }

  /// Get edit history for an event
  Future<List<MatrixEvent>> getEditHistory(
    String roomId,
    String eventId,
  ) async {
    return await getRelatedEvents(
      roomId,
      eventId,
      relationType: 'm.replace',
      limit: 50,
    );
  }

  /// Send an event (helper method)
  Future<String> sendEvent(
    String roomId,
    String type,
    Map<String, dynamic> content,
  ) async {
    final txnId = client.generateTxnId();
    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/send/$type/$txnId',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(content),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to send event: $error');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final eventId = data['event_id'] as String?;
    return eventId ?? txnId;
  }

  /// Dispose of the message operations manager
  Future<void> dispose() async {
    _logger.i('Message operations manager disposed');
  }
}

/// Reaction aggregation
class ReactionAggregation {
  /// Create a reaction aggregation from events
  factory ReactionAggregation.fromEvents(List<MatrixEvent> events) {
    final emojiCounts = <String, int>{};
    final emojiEvents = <String, List<String>>{};

    for (final event in events) {
      final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
      if (relatesTo != null && relatesTo['rel_type'] == 'm.annotation') {
        final emoji = relatesTo['key'] as String?;
        if (emoji != null) {
          emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
          emojiEvents.putIfAbsent(emoji, () => []).add(event.eventId ?? '');
        }
      }
    }

    return ReactionAggregation(
      emojiCounts: emojiCounts,
      emojiEvents: emojiEvents,
    );
  }

  /// Create a new reaction aggregation
  ReactionAggregation({
    this.emojiCounts = const {},
    this.emojiEvents = const {},
  });

  /// Map of emoji to count
  final Map<String, int> emojiCounts;

  /// Map of emoji to list of event IDs
  final Map<String, List<String>> emojiEvents;

  /// Get the count for a specific emoji
  int getCount(String emoji) => emojiCounts[emoji] ?? 0;

  /// Get all emojis with their counts
  Map<String, int> get allCounts => Map.unmodifiable(emojiCounts);

  /// Get the most popular reactions
  List<String> getTopReactions([int limit = 10]) {
    final sorted = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  /// Check if current user reacted with a specific emoji
  bool hasUserReacted(String emoji, String? userId) {
    // This would need to be implemented by checking sender IDs
    return false;
  }
}
