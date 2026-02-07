import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Account management remote datasource - implements Matrix account API
/// See: https://spec.matrix.org/v1.11/client-server-api/#profile
@injectable
class AccountRemoteDataSource {
  const AccountRemoteDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Get display name
  /// GET /_matrix/client/v3/profile/{userId}/displayname
  Future<Either<Failure, String>> getDisplayName({
    required String homeserver,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/profile/$userId/displayname');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['displayname'] as String?;
        return Right(displayName ?? '');
      } else if (response.statusCode == 404) {
        // No display name set
        return const Right('');
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get display name',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error getting display name', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set display name
  /// PUT /_matrix/client/v3/profile/{userId}/displayname
  Future<Either<Failure, void>> setDisplayName({
    required String homeserver,
    required String accessToken,
    required String userId,
    required String displayName,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/profile/$userId/displayname');

      final body = {'displayname': displayName};

      _logger.i('Setting display name: $displayName');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Display name updated');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set display name',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting display name', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get avatar URL
  /// GET /_matrix/client/v3/profile/{userId}/avatar_url
  Future<Either<Failure, String?>> getAvatarUrl({
    required String homeserver,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/profile/$userId/avatar_url');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final avatarUrl = data['avatar_url'] as String?;
        return Right(avatarUrl);
      } else if (response.statusCode == 404) {
        // No avatar set
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get avatar URL',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error getting avatar URL', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set avatar URL
  /// PUT /_matrix/client/v3/profile/{userId}/avatar_url
  Future<Either<Failure, void>> setAvatarUrl({
    required String homeserver,
    required String accessToken,
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/profile/$userId/avatar_url');

      final body = {'avatar_url': avatarUrl};

      _logger.i('Setting avatar URL: $avatarUrl');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Avatar URL updated');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set avatar URL',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting avatar URL', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Upload avatar to media repository
  /// POST /_matrix/media/v3/upload
  Future<Either<Failure, String>> uploadAvatar({
    required String homeserver,
    required String accessToken,
    required String filePath,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$cleanUrl/_matrix/media/v3/upload');

      _logger.i('Uploading avatar: $fileName (${bytes.length} bytes)');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..fields['filename'] = fileName
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ));

      final response = await request.send().timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final mxcUri = data['content_uri'] as String;

        _logger.i('Avatar uploaded: $mxcUri');
        return Right(mxcUri);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final responseBody = await response.stream.bytesToString();
        final error = jsonDecode(responseBody);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to upload avatar',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error uploading avatar', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get full profile
  /// GET /_matrix/client/v3/profile/{userId}
  Future<Either<Failure, Map<String, dynamic>>> getProfile({
    required String homeserver,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/profile/$userId');

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
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get profile',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error getting profile', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
