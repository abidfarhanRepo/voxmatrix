import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Search remote datasource - implements Matrix User Search API
/// See: https://spec.matrix.org/v1.11/client-server-api/#user-directory
@injectable
class SearchRemoteDataSource {
  const SearchRemoteDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Search for users on the homeserver
  /// POST /_matrix/client/v3/user_directory/search
  Future<Either<Failure, Map<String, dynamic>>> searchUsers({
    required String homeserver,
    required String accessToken,
    required String query,
    int limit = 10,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/user_directory/search');

      final body = {
        'search_term': query,
        'limit': limit,
      };

      _logger.i('Searching for users: $query');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        _logger.i('Found ${results.length} users');
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Search failed',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      _logger.e('Error searching users', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

