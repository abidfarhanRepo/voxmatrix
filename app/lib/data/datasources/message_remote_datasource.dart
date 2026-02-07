import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Message remote datasource - implements Matrix Client-Server API for messages
/// See: https://spec.matrix.org/v1.11/client-server-api/#sending-and-receiving-messages
@injectable
class MessageRemoteDataSource {
  const MessageRemoteDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Generate a unique transaction ID
  String _generateTxnId() => 'm${DateTime.now().millisecondsSinceEpoch}';

  /// Send a text message to a room
  /// PUT /_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}
  Future<Either<Failure, Map<String, dynamic>>> sendMessage({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String content,
    String? replyToId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final txnId = _generateTxnId();
      final uri = Uri.parse('$baseUrl/rooms/$roomId/send/m.room.message/$txnId');

      // Build message content
      final Map<String, dynamic> body;
      if (replyToId != null) {
        // Reply message
        body = {
          'msgtype': 'm.text',
          'body': content,
          'm.relates_to': {
            'rel_type': 'm.reply',
            'event_id': replyToId,
          },
        };
      } else {
        // Regular message
        body = {
          'msgtype': 'm.text',
          'body': content,
        };
      }

      _logger.i('Sending message to room: $roomId');
      _logger.d('Message content: "$content"');
      _logger.d('Request URL: $uri');
      _logger.d('Request body: $body');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('Message sent successfully: ${data['event_id']}');
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to send message',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error sending message', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get messages from a room
  /// GET /_matrix/client/v3/rooms/{roomId}/messages
  Future<Either<Failure, Map<String, dynamic>>> getMessages({
    required String homeserver,
    required String accessToken,
    required String roomId,
    String? from,
    int limit = 50,
    String dir = 'b',
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);

      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'dir': dir,
      };
      if (from != null) {
        queryParams['from'] = from;
      }

      final uri = Uri.parse('$baseUrl/rooms/$roomId/messages').replace(
        queryParameters: queryParams,
      );

      _logger.i('Getting messages from room: $roomId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('Retrieved ${data['chunk']?.length ?? 0} messages');
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get messages',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error getting messages', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Edit a message
  /// PUT /_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}
  Future<Either<Failure, Map<String, dynamic>>> editMessage({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String eventId,
    required String newContent,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final txnId = _generateTxnId();
      final uri = Uri.parse('$baseUrl/rooms/$roomId/send/m.room.message/$txnId');

      final body = {
        'msgtype': 'm.text',
        'body': "* $newContent",
        'm.new_content': {
          'msgtype': 'm.text',
          'body': newContent,
        },
        'm.relates_to': {
          'rel_type': 'm.replace',
          'event_id': eventId,
        },
      };

      _logger.i('Editing message: $eventId');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to edit message',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error editing message', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Redact (delete) a message
  /// PUT /_matrix/client/v3/rooms/{roomId}/redact/{eventId}/{txnId}
  Future<Either<Failure, Map<String, dynamic>>> redactMessage({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String eventId,
    String? reason,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final txnId = _generateTxnId();
      final uri = Uri.parse('$baseUrl/rooms/$roomId/redact/$eventId/$txnId');

      final body = <String, dynamic>{};
      if (reason != null) {
        body['reason'] = reason;
      }

      _logger.i('Redacting message: $eventId');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to redact message',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error redacting message', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Mark a room as read
  /// POST /_matrix/client/v3/rooms/{roomId}/receipt/m.read/{eventId}
  Future<Either<Failure, void>> markAsRead({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String eventId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/receipt/m.read/$eventId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to mark as read',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error marking as read', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Send typing notification
  /// PUT /_matrix/client/v3/rooms/{roomId}/typing/{userId}
  Future<Either<Failure, void>> sendTypingNotification({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String userId,
    required bool isTyping,
    int timeout = 10000,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/typing/$userId');

      final body = {
        'typing': isTyping,
        'timeout': timeout,
      };

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return const Right(null);
      } else {
        // Don't fail on typing notification errors
        return const Right(null);
      }
    } catch (e) {
      // Typing notifications are non-critical
      return const Right(null);
    }
  }

  /// Add a reaction to a message
  /// PUT /_matrix/client/v3/rooms/{roomId}/send/m.reaction/{txnId}
  Future<Either<Failure, Map<String, dynamic>>> addReaction({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String eventId,
    required String emoji,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final txnId = _generateTxnId();
      final uri = Uri.parse('$baseUrl/rooms/$roomId/send/m.reaction/$txnId');

      final body = {
        'm.relates_to': {
          'rel_type': 'm.annotation',
          'event_id': eventId,
          'key': emoji,
        },
      };

      _logger.i('Adding reaction $emoji to message $eventId');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to add reaction',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error adding reaction', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Remove a reaction (redact the reaction event)
  Future<Either<Failure, void>> removeReaction({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String reactionEventId,
  }) async {
    return await redactMessage(
      homeserver: homeserver,
      accessToken: accessToken,
      roomId: roomId,
      eventId: reactionEventId,
    );
  }

  /// Get reactions for a message
  /// GET /_matrix/client/v3/rooms/{roomId}/relations/{eventId}/m.annotation
  Future<Either<Failure, Map<String, int>>> getReactions({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String eventId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse(
        '$baseUrl/rooms/$roomId/relations/$eventId/m.annotation',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final chunk = data['chunk'] as List? ?? [];

        // Count reactions by emoji
        final reactions = <String, int>{};
        for (final event in chunk) {
          if (event is! Map<String, dynamic>) continue;

          final content = event['content'] as Map<String, dynamic>?;
          final relatesTo = content?['m.relates_to'] as Map<String, dynamic>?;

          if (relatesTo != null &&
              relatesTo['rel_type'] == 'm.annotation' &&
              relatesTo['event_id'] == eventId) {
            final emoji = relatesTo['key'] as String?;
            if (emoji != null) {
              reactions[emoji] = (reactions[emoji] ?? 0) + 1;
            }
          }
        }

        return Right(reactions);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        // Return empty reactions on error
        return const Right({});
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error getting reactions', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get context around a message (for replies)
  /// GET /_matrix/client/v3/rooms/{roomId}/context/{eventId}
  Future<Either<Failure, Map<String, dynamic>>> getMessageContext({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String eventId,
    int limit = 10,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/context/$eventId').replace(
        queryParameters: {'limit': limit.toString()},
      );

      _logger.i('Getting context for message: $eventId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get context',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error getting message context', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get a specific event by ID
  /// GET /_matrix/client/v3/rooms/{roomId}/event/{eventId}
  Future<Either<Failure, Map<String, dynamic>>> getEvent({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String eventId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/event/$eventId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else if (response.statusCode == 404) {
        throw ServerException(
          message: 'Event not found',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get event',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      _logger.e('Error getting event', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
