import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Reaction remote datasource - implements Matrix Message Reactions API
/// See: https://spec.matrix.org/v1.11/client-server-api/#mreaction
@injectable
class ReactionRemoteDataSource {
  const ReactionRemoteDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Send a reaction to a message
  /// PUT /_matrix/client/v3/rooms/{roomId}/send/m.reaction/{eventId}
  Future<Either<Failure, String>> sendReaction({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final eventId = '_reaction_${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse('$baseUrl/rooms/$roomId/send/m.reaction/$eventId');

      final body = {
        'm.relates_to': {
          'rel_type': 'm.annotation',
          'event_id': messageId,
          'key': emoji,
        },
      };

      _logger.i('Sending reaction $emoji to message $messageId');

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
        final eventIdOut = data['event_id'] as String?;
        _logger.i('Reaction sent: $eventIdOut');
        return Right(eventIdOut ?? eventId);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to send reaction',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      _logger.e('Error sending reaction', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Remove a reaction (redact the reaction event)
  /// PUT /_matrix/client/v3/rooms/{roomId}/redact/{eventId}/{txnId}
  Future<Either<Failure, void>> removeReaction({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String reactionEventId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final txnId = '_redact_${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse('$baseUrl/rooms/$roomId/redact/$reactionEventId/$txnId');

      _logger.i('Removing reaction: $reactionEventId');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'reason': 'Removing reaction'}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Reaction removed');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to remove reaction',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      _logger.e('Error removing reaction', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get reactions for a message
  /// This is done via the sync endpoint or room state aggregation
  /// For now, we'll return an empty list as the sync endpoint handles this
  Future<Either<Failure, Map<String, dynamic>>> getMessageReactions({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String messageId,
  }) async {
    // Reactions are typically obtained through the sync endpoint
    // or via relationship events
    // For now, return empty map - actual reactions come through sync
    return const Right({});
  }
}
