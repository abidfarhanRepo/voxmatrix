import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Message edit remote datasource - implements Matrix Message Editing API
/// See: https://spec.matrix.org/v1.11/client-server-api/#event-editing
@injectable
class MessageEditDataSource {
  const MessageEditDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Edit a message
  /// PUT /_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}
  Future<Either<Failure, String>> editMessage({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String messageId,
    required String newContent,
    String? originalContent,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final txnId = '_edit_${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse('$baseUrl/rooms/$roomId/send/m.room.message/$txnId');

      final body = {
        'msgtype': 'm.text',
        'body': newContent,
        'm.new_content': {
          'msgtype': 'm.text',
          'body': newContent,
        },
        'm.relates_to': {
          'rel_type': 'm.replace',
          'event_id': messageId,
        },
      };

      _logger.i('Editing message: $messageId');

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
        final eventId = data['event_id'] as String?;
        _logger.i('Message edited: $eventId');
        return Right(eventId ?? txnId);
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
    } catch (e, stackTrace) {
      _logger.e('Error editing message', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Redact (delete) a message
  /// PUT /_matrix/client/v3/rooms/{roomId}/redact/{eventId}/{txnId}
  Future<Either<Failure, void>> redactMessage({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String messageId,
    String? reason,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final txnId = '_redact_${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse('$baseUrl/rooms/$roomId/redact/$messageId/$txnId');

      _logger.i('Redacting message: $messageId');

      final body = reason != null ? {'reason': reason} : <String, dynamic>{};

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Message redacted');
        return const Right(null);
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
    } catch (e, stackTrace) {
      _logger.e('Error redacting message', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
