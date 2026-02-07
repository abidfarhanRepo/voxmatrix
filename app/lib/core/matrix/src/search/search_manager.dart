/// Search Manager for Matrix search
///
/// Handles searching messages and rooms in Matrix
/// See: https://spec.matrix.org/v1.11/client-server-api/#search

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';

/// Search Manager for search operations
class SearchManager {
  /// Create a new search manager
  SearchManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Search for messages across all rooms
  ///
  /// [query] The search query
  /// [limit] Maximum number of results to return
  /// [nextBatch] Optional pagination token for getting more results
  Future<SearchResult> searchMessages(
    String query, {
    int limit = 10,
    String? nextBatch,
  }) async {
    _logger.i('Searching for messages: $query');

    final searchPayload = {
      'search_categories': {
        'room_events': {
          'search_term': query,
          'order_by': 'recent',
          'limit': limit,
          'event_context': {
            'before_limit': 1,
            'after_limit': 1,
            'include_profile': true,
          },
        },
      },
      if (nextBatch != null) 'next_batch': nextBatch,
    };

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/search');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(searchPayload),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SearchResult.fromJson(data);
    } else {
      throw MatrixException('Search failed: ${response.statusCode}');
    }
  }

  /// Search for rooms
  ///
  /// [query] The search query
  /// [limit] Maximum number of results to return
  Future<List<RoomSearchResult>> searchRooms(
    String query, {
    int limit = 10,
  }) async {
    _logger.i('Searching for rooms: $query');

    // Get all rooms from the room manager
    final allRooms = client.roomManager.cachedRooms.values.toList();

    // Filter rooms by name or topic containing the query
    final results = allRooms
        .where((room) =>
            room.name.toLowerCase().contains(query.toLowerCase()) ||
            (room.topic?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .take(limit)
        .map((room) => RoomSearchResult(
          roomId: room.id,
          name: room.name,
          topic: room.topic,
          avatarUrl: room.avatarUrl,
          memberCount: room.joinedMemberCount,
        ))
        .toList();

    _logger.d('Found ${results.length} rooms matching: $query');
    return results;
  }

  /// Get search results grouped by room
  Future<Map<String, List<MessageSearchResult>>> searchMessagesByRoom(
    String query, {
    int limit = 10,
  }) async {
    final searchResult = await searchMessages(query, limit: limit);

    final groupedResults = <String, List<MessageSearchResult>>{};

    for (final context in searchResult.results) {
      final roomId = context.roomId;

      // Create message search result
      final result = MessageSearchResult(
        eventId: context.eventId,
        roomId: roomId,
        senderId: context.senderId,
        body: context.body,
        timestamp: context.timestamp,
        highlight: context.highlight,
      );

      groupedResults.putIfAbsent(roomId, () => []).add(result);
    }

    _logger.d('Found ${groupedResults.length} rooms with messages matching: $query');
    return groupedResults;
  }

  /// Dispose of the search manager
  Future<void> dispose() async {
    _logger.i('Search manager disposed');
  }
}

/// Search result from Matrix
class SearchResult {
  /// Create a search result from JSON
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final searchCategories = json['search_categories'] as Map<String, dynamic>?;
    final roomEvents = searchCategories?['room_events'] as Map<String, dynamic>? ?? {};
    final results = roomEvents['results'] as List? ?? [];
    final resultsList = results
        .map((r) => r is Map<String, dynamic> ? EventContext.fromJson(r) : null)
        .whereType<EventContext>()
        .toList();

    return SearchResult(
      results: resultsList,
      count: roomEvents['count'] as int? ?? 0,
      nextBatch: json['next_batch'] as String?,
    );
  }

  /// Create a new search result
  SearchResult({
    required this.results,
    required this.count,
    this.nextBatch,
  });

  /// The search results
  final List<EventContext> results;

  /// The total count of results
  final int count;

  /// Pagination token for getting more results
  final String? nextBatch;
}

/// Event context from search results
class EventContext {
  /// Create an event context from JSON
  factory EventContext.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? {};
    final context = json['context'] as Map<String, dynamic>? ?? {};

    return EventContext(
      eventId: result['event_id'] as String?,
      roomId: context['room_id'] as String? ?? '',
      senderId: result['sender_id'] as String?,
      body: result['result']?['content']?['body'] as String?,
      timestamp: result['origin_server_ts'] as int?,
      highlight: context['events_after'] is List
          ? (context['events_after'] as List)
              .map((e) => SearchHighlight.fromJson(e as Map<String, dynamic>?))
              .toList()
          : [],
    );
  }

  /// Create a new event context
  EventContext({
    required this.eventId,
    required this.roomId,
    this.senderId,
    this.body,
    this.timestamp,
    this.highlight = const [],
  });

  /// The event ID
  final String? eventId;

  /// The room ID
  final String roomId;

  /// The sender's user ID
  final String? senderId;

  /// The message body
  final String? body;

  /// The timestamp
  final int? timestamp;

  /// Search highlights
  final List<SearchHighlight> highlight;
}

/// Search highlight
class SearchHighlight {
  /// Create a search highlight from JSON
  factory SearchHighlight.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SearchHighlight();
    }
    return SearchHighlight(
      ranges: (json['ranges'] as List?)
              ?.map((r) => SearchRange.fromJson(r as Map<String, dynamic>?))
              .toList() ??
          [],
    );
  }

  /// Create a new search highlight
  const SearchHighlight({this.ranges = const []});

  /// The highlighted ranges
  final List<SearchRange> ranges;
}

/// Search range
class SearchRange {
  /// Create a search range from JSON
  factory SearchRange.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Search range JSON cannot be null');
    }
    return SearchRange(
      startIndex: json['start_index'] as int? ?? 0,
      endIndex: json['end_index'] as int? ?? 0,
      length: json['length'] as int? ?? 0,
    );
  }

  /// Create a new search range
  SearchRange({
    required this.startIndex,
    required this.endIndex,
    required this.length,
  });

  /// Start index of the highlight
  final int startIndex;

  /// End index of the highlight
  final int endIndex;

  /// Length of the highlight
  final int length;
}

/// Room search result
class RoomSearchResult {
  /// Create a new room search result
  RoomSearchResult({
    required this.roomId,
    required this.name,
    this.topic,
    this.avatarUrl,
    required this.memberCount,
  });

  /// The room ID
  final String roomId;

  /// The room name
  final String name;

  /// The room topic
  final String? topic;

  /// The room avatar URL
  final String? avatarUrl;

  /// The number of members
  final int memberCount;
}

/// Message search result
class MessageSearchResult {
  /// Create a new message search result
  MessageSearchResult({
    required this.eventId,
    required this.roomId,
    required this.senderId,
    this.body,
    this.timestamp,
    this.highlight = const [],
  });

  /// The event ID
  final String? eventId;

  /// The room ID
  final String roomId;

  /// The sender's user ID
  final String? senderId;

  /// The message body
  final String? body;

  /// The timestamp
  final int? timestamp;

  /// Search highlights
  final List<SearchHighlight> highlight;
}
